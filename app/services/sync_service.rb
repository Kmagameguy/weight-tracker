class SyncService
  OVERLAP = 5.seconds

  TYPES = {
    "tag"                    => { model: Tag,                  association: :tags,                    fields: %w[name] },
    "food_entry"             => { model: FoodEntry,            association: :food_entries,            fields: %w[name calories date] },
    "weight_entry"           => { model: WeightEntry,          association: :weight_entries,          fields: %w[weight date] },
    "blood_pressure_reading" => { model: BloodPressureReading, association: :blood_pressure_readings, fields: %w[systolic diastolic date] },
    "journal_entry"          => { model: JournalEntry,         association: :journal_entries,         fields: %w[note date] },
    "day_tag"                => { model: DayTag,               association: :day_tags,                fields: %w[date] }
  }.freeze

  def initialize(user:, cursor:, changes:)
    @user       = user
    @started_at = Time.current
    @since      = cursor.present? ? Time.iso8601(cursor) - OVERLAP : Time.at(0)
    @changes    = changes
    @extra      = []
    @rejected   = []
  end

  def call
    ActiveRecord::Base.transaction { apply_changes }

    {
      cursor: @started_at.utc.iso8601(6),
      changes: (@extra + pull_changes).uniq { |change| [ change[:op], change[:type], change[:uuid] ] },
      rejected: @rejected
    }
  end

  private

  def apply_changes
    upserts, deletes = @changes.partition { |change| change["op"] == "upsert" }
    upserts.sort_by { |change| TYPES.keys.index(change["type"]) || TYPES.size }
           .each { |change| safely(change) { upsert(change) } }
    deletes.each { |change| safely(change) { delete(change) } }
  end

  def safely(change)
    yield
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, ArgumentError, KeyError => e
    @rejected << { type: change["type"], uiud: change["uuid"], error: e.message }
  end

  def upsert(change)
    config          = TYPES.fetch(change["type"])
    scope           = @user.public_send(config[:association])
    attrs           = change.slice(*config[:fields])
    client_time     = Time.iso8601(change["client_updated_at"].to_s)
    attrs["tag_id"] = @user.tags.find_by!(uuid: change["tag_uuid"]).id if change["type"] == "day_tag"

    if (record = scope.find_by(uuid: change["uuid"]))
      record.update!(attrs) if client_time >= record.updated_at
    elsif (clash = find_clash(change["type"], scope, attrs))
      # Server copy always wins; drop the mobile copy and adopt the server's record
      clash.update!(attrs) if client_time > clash.updated_at

      @extra << { op: "delete", type: change["type"], uuid: change["uuid"] }
      @extra << serialize(clash, change["type"])
    else
      record = config[:model].new(attrs.merge("uuid" => change["uuid"]))
      record.user = @user if record.respond_to?(:user=)
      record.save!
    end
  end

  def delete(change)
    config = TYPES.fetch(change["type"])
    @user.public_send(config[:association]).find_by(uuid: change["uuid"])&.destroy!
  end

  def find_clash(type, scope, attrs)
    case type
    when "weight_entry", "blood_pressure_reading", "journal_entry"
      scope.find_by(date: attrs["date"])
    when "tag"
      scope.find_by("LOWER(name) = ?", Tag.normalize_value_for(:name, attrs["name"].to_s).downcase)
    when "day_tag"
      scope.find_by(tag_id: attrs["tag_id"], date: attrs["date"])
    end
  end

  def pull_changes
    upserts = TYPES.flat_map do |type, config|
      relation = @user.public_send(config[:association]).where(updated_at: @since..)
      relation = relation.includes(:tag) if type == "day_tag"
      relation.map { |record| serialize(record, type) }
    end

    deletes = Deletion.where(user_id: @user.id, deleted_at: @since..).map do |deletion|
      { op: "delete", type: deletion.record_type, uuid: deletion.uuid }
    end

    upserts + deletes
  end

  def serialize(record, type)
    fields = TYPES.fetch(type)[:fields].to_h { |field| [ field, record.public_send(field) ] }
    fields["tag_uuid"] = record.tag.uuid if type == "day_tag"

    { op: "upsert", type: type, uuid: record.uuid, updated_at: record.updated_at.utc.iso8601(6) }.merge(fields)
  end
end
