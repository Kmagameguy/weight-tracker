require "test_helper"

class SyncableTest < ActiveSupport::TestCase
  setup do
    @user    = users(:one)
    @subject = SyncEvent
  end

  def events_for(record)
    @subject.where(user_id: @user.id, uuid: record.uuid)
  end

  it "assigns uuids to new records" do
    new_record_uuid = @user.food_entries.create!(name: "foo", calories: 10, date: Date.current).uuid
    assigned_uuid = SecureRandom.uuid
    record_with_assigned_uuid = @user.food_entries.create!(
      name: "bar", calories: 12, date: Date.current, uuid: assigned_uuid
    )


    assert_not_nil new_record_uuid
    assert_equal assigned_uuid, record_with_assigned_uuid.uuid
  end

  it "does not allow invalid uuids" do
    [ "", "not-a-uuid", SecureRandom.uuid.upcase ].each do |invalid_uuid|
      entry = @user.food_entries.build(name: "foo", calories: 10, date: Date.current, uuid: invalid_uuid)

      assert_not_predicate entry, :valid?, "#{invalid_uuid.inspect} should be refused"
      assert_includes entry.errors.attribute_names, :uuid
    end
  end

  it "does not allow uuids to change" do
    entry = food_entries(:burrito)
    entry.uuid = SecureRandom.uuid

    assert_not_predicate entry, :valid?
    assert_includes entry.errors[:uuid], "can't be changed"
  end

  it "logs record creation, updates, and destruction unless nothing has changed" do
    entry = @user.food_entries.create!(name: "foo", calories: 90, date: Date.current)

    assert_equal 1, events_for(entry).count

    entry.save!
    entry.update!(calories: 90)
    assert_equal 1, events_for(entry).count

    entry.update!(calories: 100)
    assert_equal 2, events_for(entry).count

    entry.destroy!
    assert_equal 3, events_for(entry).count
  end

  it "pairs the event with the root record when record ancestry is involved" do
    day_tag = tags(:headache).day_tags.create!(date: Date.new(2026, 7, 1))

    assert_equal 1, @subject.where(user_id: @user.id, record_type: "day_tag", uuid: day_tag.uuid).count
  end

  it "logs all deletions within an ancestral hierarchy so devices can replay the cascade" do
    tag     = @user.tags.create!(name: "Migraine")
    day_tag = tag.day_tags.create!(date: Date.new(2026, 7, 1))
    @subject.delete_all

    tag.destroy!

    deletion_event = @subject.where(user_id: @user.id).pluck(:record_type, :uuid)
    assert_includes deletion_event, [ "tag", tag.uuid ]
    assert_includes deletion_event, [ "day_tag", day_tag.uuid ]
  end

  it "commits events inside the same transaction as the record change" do
    assert_no_difference("#{@subject.name}.count") do
      FoodEntry.transaction do
        @user.food_entries.create!(name: "foo", calories: 10, date: Date.current)
        raise ActiveRecord::Rollback
      end
    end
  end

  it "does not re-use event ids" do
    attrs = { user_id: @user.id, record_type: "food_entry" }
    first_event = @subject.create!(attrs.merge(uuid: SecureRandom.uuid))
    first_event.destroy!

    second_event = @subject.create!(attrs.merge(uuid: SecureRandom.uuid))

    assert_operator second_event.id, :>, first_event.id
  end
end
