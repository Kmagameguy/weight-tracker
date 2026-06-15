require "test_helper"

class UserTest < ActiveSupport::TestCase
  before { @user = users(:one) }

  it "exposes the default daily calorie goal constant" do
    assert defined?(User::DEFAULT_DAILY_CALORIE_GOAL)
    assert_operator User::DEFAULT_DAILY_CALORIE_GOAL, ">", 0
  end

  it "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal "downcased@example.com", user.email_address
  end

  it "exposes email as an alias for email_address" do
    assert_equal @user.email_address, @user.email
  end

  describe "validations" do
    it "is invalid without a daily_calorie_goal" do
      @user.daily_calorie_goal = nil
      assert_not_predicate @user, :valid?
      assert_includes @user.errors[:daily_calorie_goal], "can't be blank"
    end

    it "is invalid when daily_calorie_goal is zero" do
      @user.daily_calorie_goal = 0
      assert_not_predicate @user, :valid?
      assert_includes @user.errors[:daily_calorie_goal], "must be greater than 0"
    end

    it "is valid when daily_calorie_goal is a positive integer" do
      @user.daily_calorie_goal = 2_000
      assert_predicate @user, :valid?
    end

    it "is valid when a valid timezone is specified" do
      @user.timezone = ActiveSupport::TimeZone.all.map(&:tzinfo).sample.name
      assert_predicate @user, :valid?
    end

    it "is invalid with an invalid timezone" do
      @user.timezone = "not-a-timezone"
      assert_not_predicate @user, :valid?
      assert_includes @user.errors[:timezone], "is not included in the list"
    end
  end

  describe "associations" do
    it "destroys dependent sessions when the user is destroyed" do
      @user.sessions.create!
      assert_difference("Session.count", -@user.sessions.count) { @user.destroy }
    end

    it "destroys dependent food_entries when the user is destroyed" do
      assert_difference("FoodEntry.count", -@user.food_entries.count) { @user.destroy }
    end

    it "destroys dependent weight_entries when the user is destroyed" do
      assert_difference("WeightEntry.count", -@user.weight_entries.count) { @user.destroy }
    end
  end

  describe "food-related utilities" do
    describe "#days_over_budget" do
      it "counts the number of days where the sum of its food_entry calories was greater than the user's calorie goal" do
        @user.update!(daily_calorie_goal: 1_500)
        @user.food_entries.destroy_all
        {
          "#{Time.current - 1.day}" => [
            { name: "Tacos", calories: 800 },
            { name: "Ice Cream", calories: 820 }
          ],
          "#{Time.current - 1.week}" => [
            { name: "Banana", calories: 100 },
            { name: "Hot Dog", calories: 640 },
            { name: "Root Beer Float", calories: 914 }
          ],
          "#{Time.current}" => [
            { name: "Coffee", calories: 15 },
            { name: "Apple", calories: 100 }
          ]
        }.each do |timestamp, entries|
          entries.each do |entry|
            @user.food_entries.create!(date: timestamp, name: entry[:name], calories: entry[:calories])
          end
        end

        assert_equal 2, @user.days_over_budget
      end

      it "returns 0 when no food entries have been logged" do
        @user.food_entries.destroy_all

        assert_predicate @user.days_over_budget, :zero?
      end
    end

    describe "#lifetime_calorie_deficit" do
      it "shows total calorie deficit over lifetime of the account" do
        @user.update!(daily_calorie_goal: 1_500)
        @user.food_entries.destroy_all

        {
          # 1620 Calories
          "#{Date.current - 1.day}" => [
            { name: "Tacos", calories: 800 },
            { name: "Ice Cream", calories: 820 }
          ],
          # 1654 Calories
          "#{Date.current - 1.week}" => [
            { name: "Banana", calories: 100 },
            { name: "Hot Dog", calories: 640 },
            { name: "Root Beer Float", calories: 914 }
          ],
          # 115 Calories
          "#{Date.current}" => [
            { name: "Coffee", calories: 15 },
            { name: "Apple", calories: 100 }
          ]
        }.each do |timestamp, entries|
          entries.each do |entry|
            @user.food_entries.create!(date: timestamp, name: entry[:name], calories: entry[:calories])
          end
        end

        assert_equal 2611, @user.lifetime_calorie_deficit
      end

      it "returns 0 when no food entries are logged" do
        @user.food_entries.destroy_all

        assert_predicate @user.lifetime_calorie_deficit, :zero?
      end
    end

    describe "#median_calories_consumed" do
      it "returns 0 when the user has no food entries" do
        @user.food_entries.destroy_all
        assert_predicate @user.median_calories_consumed, :zero?
      end

      it "returns the single value when there is exactly one food entry" do
        @user.food_entries.destroy_all
        @user.food_entries.create!(date: Date.current, name: "PB & J", calories: 1_800)
        assert_equal 1_800, @user.median_calories_consumed
      end

      it "returns the median value for many food entries" do
        today = Date.current
        yesterday = today - 1.day
        @user.food_entries.destroy_all
        # Yesterday: 600 + 700 = 1_300
        @user.food_entries.create!(date: yesterday, name: "chicken", calories: 600)
        @user.food_entries.create!(date: yesterday, name: "beef", calories: 700)
        # Today: 900 + 900 = 1_800
        @user.food_entries.create!(date: today, name: "burger", calories: 900)
        @user.food_entries.create!(date: today, name: "tacos", calories: 900)
        # Median of [1_300, 1_800] = 1_550
        assert_equal 1_550, @user.median_calories_consumed
      end
    end
  end

  describe "weight-related utilities" do
    before do
      @user.weight_entries.destroy_all
      [
        { date: Date.current - 1.week, weight: 245.2 },
        { date: Date.current - 1.day, weight: 240.7 },
        { date: Date.current, weight: 241.9 }
      ].each do |weight_entry|
        @user.weight_entries.create!(date: weight_entry[:date], weight: weight_entry[:weight])
      end
    end

    describe "#min_recorded_weight" do
      it "returns the lowest weight value of all recorded weight values" do
        assert_equal 240.7, @user.min_recorded_weight
      end

      it "returns nil when there are no recorded weight entries" do
        @user.weight_entries.destroy_all
        assert_nil @user.min_recorded_weight
      end
    end

    describe "#max_recorded_weight" do
      it "returns the highest weight value of all recorded weight values" do
        assert_equal 245.2, @user.max_recorded_weight
      end

      it "returns nil when there are no recorded weight entires" do
        @user.weight_entries.destroy_all
        assert_nil @user.max_recorded_weight
      end
    end

    describe "#current_weight" do
      it "returns the most recently logged weight entry" do
        assert_equal 241.9, @user.current_weight
      end

      it "returns nil when no weight entries are recorded" do
        @user.weight_entries.destroy_all
        assert_nil @user.current_weight
      end
    end
  end
end
