require "test_helper"

class UserTest < ActiveSupport::TestCase
  it "exposes the default daily calorie goal constant" do
    assert defined?(User::DEFAULT_DAILY_CALORIE_GOAL)
    assert_operator User::DEFAULT_DAILY_CALORIE_GOAL, ">", 0
  end

  it "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal "downcased@example.com", user.email_address
  end

  it "exposes email as an alias for email_address" do
    user = users(:one)
    assert_equal user.email_address, user.email
  end

  describe "validations" do
    it "is invalid without a daily_calorie_goal" do
      user = users(:one)
      user.daily_calorie_goal = nil
      assert_not_predicate user, :valid?
      assert_includes user.errors[:daily_calorie_goal], "can't be blank"
    end

    it "is invalid when daily_calorie_goal is zero" do
      user = users(:one)
      user.daily_calorie_goal = 0
      assert_not_predicate user, :valid?
      assert_includes user.errors[:daily_calorie_goal], "must be greater than 0"
    end

    it "is valid when daily_calorie_goal is a positive integer" do
      user = users(:one)
      user.daily_calorie_goal = 2_000
      assert_predicate user, :valid?
    end
  end

  describe "associations" do
    it "destroys dependent sessions when the user is destroyed" do
      user = users(:one)
      user.sessions.create!
      assert_difference("Session.count", -user.sessions.count) { user.destroy }
    end

    it "destroys dependent food_entries when the user is destroyed" do
      user = users(:one)
      assert_difference("FoodEntry.count", -user.food_entries.count) { user.destroy }
    end

    it "destroys dependent weight_entries when the user is destroyed" do
      user = users(:one)
      assert_difference("WeightEntry.count", -user.weight_entries.count) { user.destroy }
    end
  end

  describe "#median_calories_consumed" do
    it "returns 0 when the user has no food entries" do
      user = users(:one)
      user.food_entries.destroy_all
      assert_predicate user.median_calories_consumed, :zero?
    end

    it "returns the single value when there is exactly one food entry" do
      user = users(:one)
      user.food_entries.destroy_all
      user.food_entries.create!(date: Date.today, name: "PB & J", calories: 1_800)
      assert_equal 1_800, user.median_calories_consumed
    end

    it "returns the median value for many food entries" do
      user = users(:one)
      today = Date.today
      yesterday = today - 1.day
      user.food_entries.destroy_all
      # Yesterday: 600 + 700 = 1_300
      user.food_entries.create!(date: yesterday, name: "chicken", calories: 600)
      user.food_entries.create!(date: yesterday, name: "beef", calories: 700)
      # Today: 900 + 900 = 1_800
      user.food_entries.create!(date: today, name: "burger", calories: 900)
      user.food_entries.create!(date: today, name: "tacos", calories: 900)
      # Median of [1_300, 1_800] = 1_550
      assert_equal 1_550, user.median_calories_consumed
    end
  end
end
