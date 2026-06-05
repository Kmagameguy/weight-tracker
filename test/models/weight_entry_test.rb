require "test_helper"

class WeightEntryTest < ActiveSupport::TestCase
  describe "validations" do
    it "is invalid without a weight" do
      weight_entry = weight_entries(:one)
      weight_entry.weight = nil
      assert_not_predicate weight_entry, :valid?
      assert_includes weight_entry.errors[:weight], "can't be blank"
    end

    it "is invalid if weight is less than 0" do
      weight_entry = weight_entries(:one)
      weight_entry.weight = -1
      assert_not_predicate weight_entry, :valid?
      assert_includes weight_entry.errors[:weight], "must be greater than or equal to 0"
    end

    it "is invalid without a date" do
      weight_entry = weight_entries(:one)
      weight_entry.date = nil
      assert_not_predicate weight_entry, :valid?
      assert_includes weight_entry.errors[:date], "can't be blank"
    end

    it "is invalid if a weight entry already exists for the given date" do
      valid_weight_entry = weight_entries(:one)
      invalid_weight_entry = WeightEntry.new(
        date: valid_weight_entry.date,
        user: valid_weight_entry.user,
        weight: 112.8
      )
      assert_not_predicate invalid_weight_entry, :valid?
      assert_includes invalid_weight_entry.errors[:date], "already has a weight entry"
    end

    it "is invalid without a user reference" do
      weight_entry = weight_entries(:one)
      weight_entry.user = nil
      assert_not_predicate weight_entry, :valid?
      assert_includes weight_entry.errors[:user], "must exist"
    end

    it "is valid with valid attributes" do
      weight_entry = WeightEntry.new(
        user: users(:one),
        weight: 121.6,
        date: Time.current
      )

      assert_predicate weight_entry, :valid?
    end
  end
end
