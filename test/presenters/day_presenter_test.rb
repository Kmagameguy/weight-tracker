require "test_helper"

class DayPresenterTest < ActiveSupport::TestCase
  setup do
    @date = Date.parse("2026-06-05 05:00:00")
    @user = users(:one)
    @presenter = DayPresenter.new(user: @user, date: @date)
  end

  describe "#prev_day" do
    it "calculates the day before the presenter's current date" do
      expected_date = @date - 1.day
      assert_equal expected_date, @presenter.prev_day
    end
  end

  describe "#next_day" do
    it "calculates the day after the presenter's current date" do
      expected_date = @date + 1.day
      assert_equal expected_date, @presenter.next_day
    end
  end

  describe "#today?" do
    it "is true if the presenter's date matches today" do
      Date.stubs(:current).returns(@date)
      assert_predicate @presenter, :today?
    end

    it "is false if the presenter's date does not match today" do
      Date.stubs(:current).returns(@date + 1.day)
      assert_not_predicate @presenter, :today?
    end
  end

  describe "#total_calories" do
    it "sums the calorie count from food entries for the given user and day" do
      [
        { name: "sushi", calories: 600 },
        { name: "apple", calories: 100 },
        { name: "soda", calories: 120 }
      ].each do |food_entry|
        @user.food_entries.create!(
          name: food_entry[:name],
          calories: food_entry[:calories],
          date: @date
        )
      end

      # sushi + apple + soda
      assert_equal 820, @presenter.total_calories
    end

    it "excludes entries from different days" do
      @user.food_entries.create!(name: "soup", calories: 810, date: @date + 1.day)

      assert_predicate @presenter.total_calories, :zero?
    end

    it "excludes entries for other users" do
      users(:two).food_entries.create!(name: "taco", calories: 310, date: @date)

      assert_predicate @presenter.total_calories, :zero?
    end
  end

  describe "#calories_remaining" do
    it "calculates the difference between the daily calorie goal and total calories consumed" do
      calorie_goal = @user.daily_calorie_goal
      food_entry = @user.food_entries.create!(name: "Burger", calories: 520, date: @date)
      expected_remaining = calorie_goal - food_entry.calories
      assert_equal expected_remaining, @presenter.calories_remaining
    end
  end

  describe "#new_food_entry" do
    it "prepares a new food entry for the presenter's user and date" do
      new_food_entry = @presenter.new_food_entry
      assert_not_predicate new_food_entry, :persisted?
      assert_equal @user, new_food_entry.user
      assert_equal @date, new_food_entry.date
    end
  end

  describe "#new_weight_entry" do
    it "prepares a new weight entry for the presenter's user and date" do
      new_weight_entry = @presenter.new_weight_entry
      assert_not_predicate new_weight_entry, :persisted?
      assert_equal @user, new_weight_entry.user
      assert_equal @date, new_weight_entry.date
    end
  end

  describe "#last_weight_entry" do
    it "returns the most recently logged weight entry" do
      [ { date: @date + 1.week, weight: 310 }, { date: @date, weight: 110.4 } ].each do |weight|
        @user.weight_entries.create!(weight: weight[:weight], date: weight[:date], user: @user)
      end

      assert_operator @presenter.user.weight_entries.count, ">", 0
      assert_equal 310, @presenter.last_weight_entry.weight
    end
  end

  describe "#weight_entry" do
    it "finds the weight entry for the presenter's user and given date" do
      @user.weight_entries.first.update!(date: @date)
      @user.weight_entries.create!(date: @date - 1.day, weight: 110.4)
      expected_weight_entry = @user.weight_entries.find_by(date: @date)

      assert_equal expected_weight_entry, @presenter.weight_entry
    end

    it "returns nil if there's no weight entry for the given user & day" do
      @user.weight_entries.destroy_all

      assert_nil @presenter.weight_entry
    end
  end

  describe "#food_entries" do
    it "returns all food entries for the given user & day" do
      @user.food_entries.each { |food_entry| food_entry.update!(date: @date) }
      @user.food_entries.create!(name: "pizza", calories: 1_200, date: @date)
      expected_count = @user.food_entries.where(date: @date).count

      assert_equal expected_count, @presenter.food_entries.count
    end

    it "sorts food entries by their created_at date" do
      entries = %w[pizza sushi].map.with_index do |food, index|
        @user.food_entries.create!(
          name: food,
          calories: rand(100..250),
          date: @date,
          created_at: @date - index.hour,
          updated_at: @date - index.hour
        )
      end

      assert_equal entries.reverse, @presenter.food_entries
    end

    it "excludes food entries for a different user" do
      irrelevant_food_entry = users(:two).food_entries.create!(name: "pizza", calories: 1_200, date: @date)

      assert_not_includes @presenter.food_entries, irrelevant_food_entry
    end

    it "excludes food entries from a different date" do
      irrelevant_food_entry = @user.food_entries.create!(name: "pizza", calories: 1_200, date: @date - 1.day)

      assert_not_includes @presenter.food_entries, irrelevant_food_entry
    end
  end

  describe "#weight_entries" do
    it "returns all weight entries for the given user" do
      total_weight_entries = WeightEntry.all.count
      total_user_weight_entries = @user.weight_entries.count

      assert_not_empty @presenter.weight_entries
      assert_operator total_weight_entries, ">", @presenter.weight_entries.count
      assert_equal total_user_weight_entries, @presenter.weight_entries.count
      assert @presenter.weight_entries.all? { |we| we.user == @user }
    end
  end
end
