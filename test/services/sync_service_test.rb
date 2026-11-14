require "test_helper"

class SyncServiceTest < ActiveSupport::TestCase
  ONE_ENTRY_PER_DAY = {
    "weight_entry"           => [ { weight: "200.0" },              { weight: "190.0" } ],
    "blood_pressure_reading" => [ { systolic: 120, diastolic: 80 }, { systolic: 110, diastolic: 70 } ],
    "journal_entry"          => [ { note: "from the web" },         { note: "from the phone" } ]
  }.freeze

  setup do
    # Don't use users(:one) here because its fixtures will get in the way
    @user = User.create!(email_address: "sync-test@example.com", password: "password123", daily_calorie_goal: 2_000)
    @other_user = users(:two)
  end

  def sync(changes = [], cursor: nil, user: @user)
    SyncService.new(user: user, cursor: cursor, changes: changes).call
  end

  def user_today
    Time.current.in_time_zone(@user.timezone).to_date
  end

  def now_as_iso
    Time.current.iso8601(6)
  end

  def food(uuid = SecureRandom.uuid, **overrides)
    {
      type: "food_entry",
      op: "upsert",
      uuid: uuid,
      name: "foo",
      calories: 12,
      date: user_today.iso8601,
      client_updated_at: now_as_iso
    }.merge(overrides)
  end

  def weight(uuid = SecureRandom.uuid, **overrides)
    {
      type: "weight_entry",
      op: "upsert",
      uuid: uuid,
      weight: "199.0",
      date: user_today.iso8601, client_updated_at: now_as_iso
    }.merge(overrides)
  end

  def deletion(type, uuid)
    { type: type, op: "delete", uuid: uuid }
  end

  def new_food(**attrs)
    @user.food_entries.create!({ name: "foo", calories: 12, date: user_today }.merge(attrs))
  end

  def changes_of(result, op: nil, type: nil)
    result[:changes].select do |change|
      (op.nil? || change[:op] == op) && (type.nil? || change[:type] == type)
    end
  end

  def uuids(list)
    list.map { |entry| entry[:uuid] }
  end

  def rejection_codes(result)
    result[:rejected].map { |rejection| rejection[:code] }
  end

  def assert_attributes(record, expected)
    expected.each do |name, value|
      cast = record.class.type_for_attribute(name.to_s).cast(value)
      assert_equal cast, record.public_send(name), name.to_s
    end
  end

  def count_queries
    count   = 0
    counter = lambda do |*, payload|
      ignored = payload[:cached] || %w[SCHEMA TRANSACTION].include?(payload[:name])
      count += 1 unless ignored
    end

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { yield }
    count
  end

  describe "pushing changes" do
    it "creates a record using the device's uuid and echoes the server copy" do
      uuid   = SecureRandom.uuid
      result = sync([ food(uuid, name: "    Tuna   Sandwich ") ])

      assert_equal "Tuna Sandwich", @user.food_entries.find_by!(uuid: uuid).name
      assert_equal "Tuna Sandwich", changes_of(result, type: "food_entry").sole[:name]
      assert_empty result[:rejected]
    end

    it "treats a repeat push as a no-op instead of a conflict or duplicate" do
      change = food
      sync([ change ])

      assert_no_difference("SyncEvent.count") do
        assert_empty sync([ change ])[:rejected]
      end

      assert_equal 1, FoodEntry.where(uuid: change[:uuid]).count
    end

    it "doesn't let a bad change block subsequent processing" do
      good_entry = food
      bad_entry  = food(calories: -5)
      result     = sync([ bad_entry, good_entry ])

      assert FoodEntry.exists?(uuid: good_entry[:uuid])
      assert_not FoodEntry.exists?(uuid: bad_entry[:uuid])
      assert_equal [ bad_entry[:uuid] ], uuids(result[:rejected])
      assert_equal [ "invalid" ], rejection_codes(result)
    end

    it "ignores attributes the sync API isn't configured to read/write" do
      uuid  = SecureRandom.uuid
      sync([ food(uuid, user_id: @other_user.id, id: 999_999, created_at: 10.years.ago.iso8601) ])
      record = FoodEntry.find_by!(uuid: uuid)

      assert_equal @user, record.user
      assert_not_equal 999_999, record.id
      assert_operator record.created_at, :>, 1.minute.ago
    end

    it "rejects non-scalar values" do
      result = sync([ food(name: [ "a" ]), food(calories: { "$gt" => 0 }) ])

      assert_equal [ "invalid", "invalid" ], rejection_codes(result)
      assert_empty @user.food_entries
    end

    it "can't steal or delete another user's record" do
      victim = @other_user.food_entries.create!(name: "Salad", calories: 320, date: user_today)
      result = sync([ food(victim.uuid, name: "Hijacked"), deletion("food_entry", victim.uuid) ])

      assert_equal "Salad", victim.reload.name
      assert_equal [ "conflict" ], rejection_codes(result)
    end

    it "rejects other invalid data" do
      good_entry = new_food
      bad_entries = [
        food("not-a-uuid"),
        food(SecureRandom.uuid.upcase),
        food(type: "mystery"),
        food.except(:uuid),
        { type: "food_entry", op: "remove", uuid: good_entry.uuid }
      ]
      result = sync(bad_entries)

      assert_equal 5, result[:rejected].size
      assert FoodEntry.exists?(good_entry.id)
    end

    it "treats deleting an unknown record as a no-op" do
      assert_empty sync([ deletion("food_entry", SecureRandom.uuid) ])[:rejected]
    end

    it "rolls back the transaction on an unexpected error" do
      existing_entry = new_food
      WeightEntry.any_instance.stubs(:save!).raises(StandardError, "woops!")

      assert_raises(StandardError) { sync([ deletion("food_entry", existing_entry.uuid), weight ]) }
      assert FoodEntry.exists?(existing_entry.id)
    end
  end

  describe "pulling changes" do
    it "returns a user's complete dataset on first sync" do
      user_food = new_food
      @other_user.food_entries.create!(name: "bar", calories: 6, date: user_today)

      assert_equal [ user_food.uuid ], uuids(changes_of(sync, type: "food_entry"))
    end

    it "returns only what changed after the submitted cursor" do
      new_food
      cursor = sync[:cursor]
      fresh_entry = new_food(name: "Salad")

      assert_equal [ fresh_entry.uuid ], uuids(sync(cursor: cursor)[:changes])
    end

    it "tracks changes regardless of timezones/timestamps" do
      cursor = sync[:cursor]
      travel_to(1.year.ago) { new_food(name: "Backdated entry") }

      entry_names = sync(cursor: cursor)[:changes].map { |change| change[:name] }
      assert_equal [ "Backdated entry" ], entry_names
    end

    it "collapses many changes to a record into its latest state" do
      entry = new_food(calories: 1)
      entry.update!(calories: 2)
      entry.update!(calories: 3)

      calories = changes_of(sync, type: "food_entry").map { |change| change[:calories] }
      assert_equal [ 3 ], calories
    end

    it "always relays deletions" do
      cursor = sync[:cursor]
      deleted_entry = new_food
      deleted_entry.destroy!

      assert_equal [ { op: "delete", type: "food_entry", uuid: deleted_entry.uuid } ], sync(cursor: cursor)[:changes]
    end

    it "rejects an invalid cursor" do
      assert_raises(SyncService::InvalidCursor) { sync(cursor: (sync[:cursor].to_i + 1_000).to_s) }

      [ "abc", "-1", "1.5", "1e3", "1_0", "{}" ].each do |invalid_cursor|
        assert_raises(SyncService::InvalidCursor, invalid_cursor) { sync(cursor: invalid_cursor) }
      end
    end

    it "uses efficient queries" do
      tag = @user.tags.create!(name: "Migraine")
      25.times do |index|
        new_food(name: "Food #{index}")
        tag.day_tags.create!(date: user_today - index)
      end

      assert_operator count_queries { sync }, :<, 15
    end
  end

  describe "conflicts between devices" do
    it "applies edits even when the device's clock is behind the server's" do
      entry  = new_food
      cursor = sync[:cursor]

      sync([ food(entry.uuid, calories: 120, client_updated_at: 1.hour.ago.iso8601(6)) ], cursor: cursor)

      assert_equal 120, entry.reload.calories
    end

    it "will use the newer server edit to resolve conflicts" do
      entry  = new_food
      cursor = sync[:cursor]
      # Simulate web (server)-side change after last sync
      entry.update!(calories: 500)

      # Simulate device edit of same entry before server edit
      result = sync([ food(entry.uuid, calories: 120, client_updated_at: 1.hour.ago.iso8601(6)) ], cursor: cursor)

      assert_equal 500, entry.reload.calories
      assert_equal [ "superseded" ], rejection_codes(result)
      assert_equal [ 500 ], changes_of(result, type: "food_entry").map { |change| change[:calories] }
    end

    it "will use the newer device edit to resolve conflicts" do
      entry  = new_food
      cursor = sync[:cursor]
      travel_to(1.hour.ago) { entry.update!(calories: 500) }

      sync([ food(entry.uuid, calories: 120, client_updated_at: 10.minutes.ago.iso8601(6)) ], cursor: cursor)

      assert_equal 120, entry.reload.calories
    end

    it "assumes a missing/invalid timestamp is the oldest edit in a conflict" do
      [ nil, "", "yesterday", 12_345 ].each do |invalid_time|
        uuid = SecureRandom.uuid

        assert_empty sync([ food(uuid, client_updated_at: invalid_time) ])[:rejected]
        assert FoodEntry.exists?(uuid: uuid)
      end

      entry  = new_food
      cursor = sync[:cursor]
      entry.update!(calories: 500)
      result = sync([ food(entry.uuid, calories: 120, client_updated_at: "garbage") ], cursor: cursor)

      assert_equal [ "superseded" ], rejection_codes(result)
    end

    it "instructs a device to drop a deleted record instead of resurrecting it" do
      entry  = new_food
      cursor = sync[:cursor]
      entry.destroy!

      result = sync([ food(entry.uuid, calories: 500) ], cursor: cursor)

      assert_not FoodEntry.exists?(uuid: entry.uuid)
      assert_equal [ "deleted" ], rejection_codes(result)
      assert_includes uuids(changes_of(result, op: "delete")), entry.uuid
    end

    it "allows a device's record deletion to win over a conflicting server (web) edit" do
      entry  = new_food
      cursor = sync[:cursor]
      entry.update!(calories: 550)

      sync([ deletion("food_entry", entry.uuid) ], cursor: cursor)

      assert_not FoodEntry.exists?(entry.id)
    end

    it "allows a device's weigh-in replace an old server-side weigh-in through delete-and-replace" do
      old_entry   = @user.weight_entries.create!(date: user_today, weight: 190)
      replacement = SecureRandom.uuid

      sync([ weight(replacement), deletion("weight_entry", old_entry.uuid) ], cursor: sync[:cursor])

      assert_equal [ replacement ], @user.weight_entries.pluck(:uuid)
    end

    ONE_ENTRY_PER_DAY.each do |type, (server_attrs, phone_attrs)|
      describe "two devices logging the same day's #{type}" do
        before do
          @type         = type
          @model        = type.camelize.constantize
          @server_attrs = server_attrs
          @phone_attrs  = phone_attrs
          @day          = user_today
          @phone_uuid   = SecureRandom.uuid
        end

        def log_from_server
          server = nil
          travel_to(1.hour.ago) { server = @model.create!({ user: @user, date: @day }.merge(@server_attrs)) }
          server
        end

        def phone_change(edited_at)
          {
            type: @type,
            op: "upsert",
            uuid: @phone_uuid,
            date: @day.iso8601,
            client_updated_at: edited_at.iso8601(6)
          }.merge(@phone_attrs)
        end

        it "keeps one row and uses the newer device data" do
          server = log_from_server
          result = sync([ phone_change(10.minutes.ago) ])

          assert_equal [ server.uuid ], @model.where(user_id: @user.id, date: @day).pluck(:uuid)
          assert_attributes server.reload, @phone_attrs
          assert_includes uuids(changes_of(result, op: "delete", type: @type)), @phone_uuid
          assert_includes uuids(changes_of(result, op: "upsert", type: @type)), server.uuid
        end

        it "keeps one row, retains the newer server data, and tells the device to match the server" do
          server = log_from_server
          result = sync([ phone_change(2.hours.ago) ])

          assert_equal 1, @model.where(user_id: @user.id, date: @day).count
          assert_attributes server.reload, @server_attrs
          assert_includes uuids(changes_of(result, op: "delete", type: @type)), @phone_uuid
          assert_includes uuids(changes_of(result, op: "upsert", type: @type)), server.uuid
        end
      end
    end
  end

  describe "tags and day tags" do
    def tag_change(uuid, name)
      {
        type: "tag",
        op: "upsert",
        uuid: uuid,
        name: name,
        client_updated_at: now_as_iso
      }
    end

    def day_tag_change(uuid, tag_uuid, **overrides)
      {
        type: "day_tag",
        op: "upsert",
        uuid: uuid,
        tag_uuid: tag_uuid,
        date: user_today.iso8601,
        client_updated_at: now_as_iso
      }.merge(overrides)
    end

    it "creates a tag and its day tag in one batch, regardless of messaging order" do
      tag_uuid, day_tag_uuid = [ SecureRandom.uuid, SecureRandom.uuid ]

      result = sync([ day_tag_change(day_tag_uuid, tag_uuid), tag_change(tag_uuid, "Migraine") ])

      assert_empty result[:rejected]
      assert_equal [ day_tag_uuid ], @user.tags.find_by!(uuid: tag_uuid).day_tags.pluck(:uuid)
    end

    it "attaches a new day tag to the tag that won a conflict" do
      winning_tag = @user.tags.create!(name: "Migraine")
      tag_uuid, day_tag_uuid = [ SecureRandom.uuid, SecureRandom.uuid ]

      result = sync([ day_tag_change(day_tag_uuid, tag_uuid), tag_change(tag_uuid, "migraine") ])

      assert_empty result[:rejected]
      assert_equal [ day_tag_uuid ], winning_tag.day_tags.pluck(:uuid)
      assert_includes uuids(changes_of(result, op: "delete", type: "tag")), tag_uuid
    end

    it "won't attribute day tags to the incorrect user" do
      other_user_tag = @other_user.tags.create!(name: "Something")

      result = sync([ day_tag_change(SecureRandom.uuid, other_user_tag.uuid) ])

      assert_equal [ "invalid" ], rejection_codes(result)
      assert_empty other_user_tag.day_tags
    end

    it "prevents orphaned day tags when the parent tag was deleted on the server" do
      deleted_tag = @user.tags.create!(name: "Migraine")
      cursor      = sync[:cursor]
      deleted_tag.destroy!

      result = sync([ day_tag_change(SecureRandom.uuid, deleted_tag.uuid) ], cursor: cursor)

      assert_equal [ "deleted" ], rejection_codes(result)
    end

    it "prevents a tag change that conflicts with another existing tag" do
      existing_tag    = @user.tags.create!(name: "Migraine")
      conflicting_tag = @user.tags.create!(name: "Allergies")

      result = sync([ tag_change(conflicting_tag.uuid, "migraine") ], cursor: sync[:cursor])

      assert_equal [ "invalid" ], rejection_codes(result)
      assert_equal [ "Migraine", "Allergies" ], [ existing_tag.reload.name, conflicting_tag.reload.name ]
    end
  end

  describe "input limits" do
    it "limits batch sizes" do
      full_batch = Array.new(SyncService::MAX_CHANGES) { deletion("food_entry", SecureRandom.uuid) }
      assert_empty sync(full_batch)[:rejected]

      good_entry = food
      assert_raises(SyncService::TooManyChanges) { sync([ good_entry ] + full_batch) }
      assert_not FoodEntry.exists?(uuid: good_entry[:uuid])
    end

    it "only works with an array of objects" do
      good_entry = food

      [
        [ good_entry, "oops" ],
        "nope",
        { "0" => good_entry }
      ].each do |invalid_payload|
        assert_raises(SyncService::InvalidRequest) { sync(invalid_payload) }
      end

      assert_not FoodEntry.exists?(uuid: good_entry[:uuid])
    end

    it "allows submissions for 1-day-in-the-future but rejects future or weird ones" do
      entry_for_tomorrow = food(date: (user_today + 1).iso8601)
      bad_entries = [ food(date: "1999-12-31"), food(date: (user_today + 2).iso8601), food(date: "invalid-date") ]

      result = sync([ entry_for_tomorrow ] + bad_entries)

      assert FoodEntry.exists?(uuid: entry_for_tomorrow[:uuid])
      assert_equal bad_entries.map { |change| change[:uuid] }.sort, uuids(result[:rejected]).sort
    end

    it "rejects invalid data without blocking the whole batch" do
      good_entry = food
      result     = sync([ food(calories: -5), weight(weight: "-10"), good_entry ])

      assert_equal [ "invalid", "invalid" ], rejection_codes(result)
      assert FoodEntry.exists?(uuid: good_entry[:uuid])
    end
  end
end
