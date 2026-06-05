require "test_helper"

class FoodEntryTest < ActiveSupport::TestCase
  describe "validations" do
    it "is invalid without a name" do
      food_entry = food_entries(:burrito)
      food_entry.name = nil
      assert_not_predicate food_entry, :valid?
      assert_includes food_entry.errors[:name], "can't be blank"
    end

    it "is invalid without a calorie value" do
      food_entry = food_entries(:burrito)
      food_entry.calories = nil
      assert_not_predicate food_entry, :valid?
      assert_includes food_entry.errors[:calories], "can't be blank"
    end

    it "is invalid if calories are negative" do
      food_entry = food_entries(:burrito)
      food_entry.calories = -1
      assert_not_predicate food_entry, :valid?
      assert_includes food_entry.errors[:calories], "must be greater than or equal to 0"
    end

    it "is invalid without a date" do
      food_entry = food_entries(:burrito)
      food_entry.date = nil
      assert_not_predicate food_entry, :valid?
      assert_includes food_entry.errors[:date], "can't be blank"
    end

    it "is invalid without a user" do
      food_entry = food_entries(:burrito)
      food_entry.user = nil
      assert_not_predicate food_entry, :valid?
      assert_includes food_entry.errors[:user], "must exist"
    end

    it "is valid with valid attributes" do
      food_entry = FoodEntry.new(date: Time.current, name: "Tuna Sandwich", calories: 310, user: users(:one))
      assert_predicate food_entry, :valid?
    end
  end
end
