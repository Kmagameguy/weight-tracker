require "test_helper"

class DayTagTest < ActiveSupport::TestCase
  describe "#validations" do
    it "is valid with valid attributes" do
      assert_predicate day_tags(:headache_on_june_fifth), :valid?
    end

    it "is invalid without a date" do
      day_tag = day_tags(:headache_on_june_fifth)
      day_tag.date = nil

      assert_not_predicate day_tag, :valid?
      assert_includes day_tag.errors[:date], "can't be blank"
    end

    it "is invalid if the tag is already applied on that date" do
      existing_day_tag  = day_tags(:headache_on_june_fifth)
      duplicate_day_tag = DayTag.new(tag: existing_day_tag.tag, date: existing_day_tag.date)

      assert_not_predicate duplicate_day_tag, :valid?
    end

    it "is invalid without a tag" do
      day_tag = day_tags(:headache_on_june_fifth)
      day_tag.tag = nil

      assert_not_predicate day_tag, :valid?
    end
  end
end
