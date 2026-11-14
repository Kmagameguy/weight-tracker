# frozen_string_literal: true

# Responsible for applying a device's queued changes.
#
# THE MODEL
#   * Identity: every record has a client-generated, lowercase UUID.
#   * Feed: SyncEvent ids act as the cursor (aka "you've seen all events up to N"). Events
#     are committed in the same transaction as their associated records. Using SQLite ensures
#     we don't need to do anything to mitigate concurrent writes.
#   * Conflicts: Typically, server-side record wins. If server record was altered after the device's
#     cursor, then we fall back to comparing time stamps. "Delete" actions take precedence over
#     everything else.
#   * Unique records: (models that declare a `unique_by` constraint, e.g. one weigh-in per day): Only
#     one record per user per day is retained; server-side always beats device record.
#
# KNOWN LIMITATION: Sync API might have issues when user's have more than one "satellite" device.
# Offline edits to the same record across multiple devices can clobber each other.
#
# ERRORS: Bad data is rejected but does not block subsequent transfers.  Unexpected errors propagate so
# the request is rolled back rather than discarding device's data.

class SyncService
  MAX_CHANGES   = 1_000
  PULL_BATCH    = 500
  EARLIEST_DATE = Date.new(2000, 1, 1)
  OPS           = %w[upsert delete].freeze
  UUID_FORMAT   = Syncable::UUID_FORMAT

  class InvalidRequest < StandardError; end
  class TooManyChanges < InvalidRequest; end
  class InvalidCursor  < InvalidRequest; end

  # Raised when a change can't be applied. We return a code
  # so the device can respond however necessary. For example:
  #   deleted, superseded -> drop the queued change
  #   conflict, invalid   -> we can't do anything with this, decide
  #                          whether to keep on device or discard
  class Rejected < StandardError
    attr_reader :code

    def initialize(code, message)
      super(message)
      @code = code
    end
  end

  def initialize(user:, cursor:, changes:)
    @user         = user
    @types        = SyncRegistry.by_type
    @rank         = @types.keys.each_with_index.to_h
    @since        = parse_cursor(cursor)
    @changes      = validate_shape!(changes)
    @received_at  = Time.current
    @aliases      = {} # [type, device uuid] => surviving record when resolving a conflict
    @deleted_here = Set.new
    @extra        = []
    @rejected     = []
  end

  def call
    ActiveRecord::Base.transaction do
      raise InvalidCursor, "cursor is ahead of the server" if @since > SyncEvent.maximum(:id).to_i

      @concurrent = events_after_cursor
      apply_changes

      up_to = SyncEvent.maximum(:id).to_i
      { cursor: up_to.to_s, changes: pull(up_to), rejected: @rejected }
    end
  end

  private

  def parse_cursor(value)
    return 0 if value.blank?

    text = value.to_s
    raise InvalidCursor, "malformed cursor" unless text.match?(/\A\d{1,18}\z/)

    text.to_i
  end

  def validate_shape!(changes)
    return [] if changes.blank?
    raise InvalidRequest, "changes must be an array" unless changes.is_a?(Array)
    raise TooManyChanges, "at most #{MAX_CHANGES} changes per request" if changes.size > MAX_CHANGES
    raise InvalidRequest, "each change must be an object" unless changes.all?(Hash)

    changes.map(&:stringify_keys)
  end

  def events_after_cursor
    SyncEvent.where(user_id: @user.id)
            .where("id > ?", @since)
            .distinct
            .pluck(:record_type, :uuid)
            .to_set
  end

  def apply_changes
    valid_changes, invalid_changes = @changes.partition { |change| valid_change?(change) }
    invalid_changes.each { |change| reject(change, :invalid, "malformed change") }

    deletes, upserts = valid_changes.partition { |change| change["op"] == "delete" }
    deletes.each { |change| safely(change) { delete(change) } }

    ordered_upserts = upserts.each_with_index.sort_by { |change, index| [ @rank.fetch(change["type"]), index ] }
    ordered_upserts.each { |change, _| safely(change) { upsert(change) } }
  end

  def valid_change?(change)
    OPS.include?(change["op"]) &&
      @types.key?(change["type"]) &&
      change["uuid"].to_s.match?(UUID_FORMAT)
  end

  def safely(change)
    ActiveRecord::Base.transaction(requires_new: true) { yield }
  rescue Rejected => error
    reject(change, error.code, error.message)
  rescue ActiveRecord::RecordInvalid => error
    reject(change, :invalid, error.record.errors.full_messages.to_sentence)
  rescue ActiveRecord::RecordNotUnique
    reject(change, :conflict, "conflicts with an existing record")
  rescue ActiveModel::RangeError
    reject(change, :invalid, "value out of range")
  end

  def reject(change, code, message)
    @rejected << {
      type: change["type"].to_s.first(40),
      uuid: change["uuid"].to_s.first(64),
      code: code.to_s,
      error: message.to_s.first(200)
    }
  end

  def upsert(change)
    type  = change["type"]
    model = @types.fetch(type)
    scope = model.owned_by(@user)
    key   = [ type, change["uuid"] ]
    attrs = writable_attributes(model, change)

    record = scope.find_by(uuid: change["uuid"])

    if record
      update_existing(change, record, attrs, key)
    elsif @concurrent.include?(key)
      raise Rejected.new(:deleted, "deleted on the server since your last sync")
    elsif (clash = model.find_sync_clash(scope, attrs))
      resolve_clash(change, clash, attrs)
    else
      create_record(model, change, attrs)
    end
  end

  # Filters any inputs that aren't part of the models'
  # "syncs" allowlist.
  def writable_attributes(model, change)
    config = model.sync_config
    attrs  = change.slice(*config[:fields])

    attrs.each_value do |value|
      raise Rejected.new(:invalid, "values must be plain strings or numbers") unless scalar?(value)
    end

    attrs["date"] = checked_date(attrs["date"]) if config[:fields].include?("date")
    attrs["#{config[:parent]}_id"] = resolve_parent(model, change).id if config[:parent]
    attrs
  end

  def scalar?(value)
    value.nil? || value.is_a?(String) || value.is_a?(Numeric) || value == true || value == false
  end

  def checked_date(value)
    date   = Date.iso8601(value.to_s)
    latest = Time.current.in_time_zone(@user.timezone).to_date + 1
    raise Rejected.new(:invalid, "date out of range") unless date.between?(EARLIEST_DATE, latest)

    date
  rescue Date::Error
    raise Rejected.new(:invalid, "invalid date")
  end

  def resolve_parent(model, change)
    name         = model.sync_config[:parent]
    parent_model = model.reflect_on_association(name).klass
    key          = [ parent_model.sync_type, change["#{name}_uuid"].to_s ]

    parent = @aliases[key] || parent_model.owned_by(@user).find_by(uuid: key.last)
    return parent if parent

    gone = @concurrent.include?(key) || @deleted_here.include?(key)
    raise Rejected.new(gone ? :deleted : :invalid, "#{name} not found")
  end

  def create_record(model, change, attrs)
    raise Rejected.new(:conflict, "uuid already in use") if model.exists?(uuid: change["uuid"])

    record = model.new(attrs.merge("uuid" => change["uuid"]))
    record.user = @user if record.respond_to?(:user=)
    record.save!
  end

  def update_existing(change, record, attrs, key)
    record.assign_attributes(attrs)
    return unless record.changed?

    if @concurrent.include?(key) && edited_at(change) < record.updated_at
      raise Rejected.new(:superseded, "the server has a newer version")
    end

    record.save!
  end

  def resolve_clash(change, clash, attrs)
    clash.update!(attrs) if edited_at(change) > clash.updated_at
    @aliases[[ change["type"], change["uuid"] ]] = clash
    @extra << { op: "delete", type: change["type"], uuid: change["uuid"] }
    @extra << serialize(clash)
  end

  def delete(change)
    type   = change["type"]
    record = @types.fetch(type).owned_by(@user).find_by(uuid: change["uuid"])
    return unless record

    record.destroy!
    @deleted_here << [ type, change["uuid"] ]
  end

  def edited_at(change)
    [ Time.iso8601(change["client_updated_at"].to_s), @received_at ].min
  rescue ArgumentError
    Time.at(0)
  end

  def pull(up_to)
    pairs = SyncEvent.where(user_id: @user.id, id: (@since + 1)..up_to)
                     .distinct
                     .pluck(:record_type, :uuid)
    uuids_by_type = pairs.group_by(&:first).transform_values { |rows| rows.map(&:last) }

    records = @types.flat_map do |type, model|
      uuids = uuids_by_type[type] || []
      uuids.each_slice(PULL_BATCH).flat_map { |batch| changes_for(type, model, batch) }
    end

    (@extra + records).uniq { |change| [ change[:op], change[:type], change[:uuid] ] }
  end

  def changes_for(type, model, uuids)
    parent   = model.sync_config[:parent]
    relation = model.owned_by(@user).where(uuid: uuids)
    relation = relation.includes(parent) if parent
    found    = relation.index_by(&:uuid)

    uuids.map do |uuid|
      found[uuid] ? serialize(found[uuid]) : { op: "delete", type: type, uuid: uuid }
    end
  end

  def serialize(record)
    config = record.class.sync_config
    parent = config[:parent]
    fields = config[:fields].to_h { |field| [ field.to_sym, record.public_send(field) ] }
    fields[:"#{parent}_uuid"] = record.public_send(parent).uuid if parent

    {
      op: "upsert",
      type:       record.sync_type,
      uuid:       record.uuid,
      updated_at: record.updated_at.utc.iso8601(6)
    }.merge(fields)
  end
end
