require "test_helper"

class WeeklyHealthSummaryPresenterTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  describe "#initialize" do
    it "sets up user, week_start, and week_end accessors" do
      presenter = WeeklyHealthSummaryPresenter.new(@user)

      assert_equal @user, presenter.user
      assert_equal Date.current.beginning_of_week, presenter.week_start
      assert_equal Date.current.beginning_of_week + 6.days, presenter.week_end
    end
  end

  describe "#previous_week" do
    it "instantiates a WeeklyHealthSummaryPresenter for week_start minus 7 days" do
      presenter = WeeklyHealthSummaryPresenter.new(@user)

      assert_equal Date.current.beginning_of_week - 7.days, presenter.previous_week.week_start
    end
  end

  describe "#avg_daily_calories" do
    it "returns nil if the user has opted out of calorie tracking" do
      @user.calorie_tracking_enabled = false
      presenter = WeeklyHealthSummaryPresenter.new(@user)
      assert_nil presenter.avg_daily_calories
    end

    it "returns nil if the user's food entry calorie totals are blank" do
      @user.food_entries.destroy_all
      presenter = WeeklyHealthSummaryPresenter.new(@user)
      assert_nil presenter.avg_daily_calories
    end

    it "returns an average daily calorie sum" do
      beginning_of_week = Date.current.beginning_of_week
      today = beginning_of_week + 2.days
      yesterday = today - 1.day
      last_week = today - 1.week

      [
        { name: "Banana", calories: 100, date: today },
        { name: "Tacos",  calories: 810, date: today },
        { name: "Popsicle", calories: 140, date: yesterday },
        { name: "Fish",   calories: 340, date: yesterday },
        { name: "Burger", calories: 820, date: yesterday },
        { name: "Soda",   calories: 150, date: last_week },
        { name: "Fruit Cup", calories: 60, date: last_week },
        { name: "Pizza", calories: 820, date: last_week }
      ].each do | item |
        @user.food_entries.create!(name: item[:name], calories: item[:calories], date: item[:date])
      end

      presenter = WeeklyHealthSummaryPresenter.new(@user)
      assert_equal 1_105, presenter.avg_daily_calories
    end
  end

  describe "#weight_change" do
    it "returns nil if the user has opted out of weight tracking" do
      @user.weight_tracking_enabled = false
      assert_nil WeeklyHealthSummaryPresenter.new(@user).weight_change
    end

    it "returns nil if the user has no weight entries" do
      @user.weight_entries.destroy_all
      assert_nil WeeklyHealthSummaryPresenter.new(@user).weight_change
    end

    it "returns zero if there's only one weight_entry" do
      (@user.weight_entries.count - 1).times do |_index|
        @user.weight_entries.last.destroy
      end

      @user.weight_entries.last.update!(date: Date.current)

      assert_equal 1, @user.weight_entries.count
      assert_predicate WeeklyHealthSummaryPresenter.new(@user).weight_change, :zero?
    end

    it "returns the difference between the first and last recorded weights from the week" do
      beginning_of_week = Date.current.beginning_of_week
      today = beginning_of_week + 2.days
      yesterday = today - 1.day

      @user.weight_entries.destroy_all
      [ { weight: 210.1, date: beginning_of_week },
        { weight: 233.5, date: yesterday },
        { weight: 198.7, date: today } ].each do |weight|
        @user.weight_entries.create!(weight: weight[:weight], date: weight[:date])
      end

      assert_equal(-11.4, WeeklyHealthSummaryPresenter.new(@user).weight_change)
    end
  end

  describe "#avg_blood_pressure" do
    it "returns nil if the user has opted out of weight tracking" do
      @user.blood_pressure_tracking_enabled = false
      assert_nil WeeklyHealthSummaryPresenter.new(@user).avg_blood_pressure
    end

    it "returns nil if the user has no blood pressure entries" do
      @user.blood_pressure_readings.destroy_all
      assert_nil WeeklyHealthSummaryPresenter.new(@user).avg_blood_pressure
    end

    it "returns the bp value if only one bp reading is available" do
      (@user.blood_pressure_readings.count - 1).times do |_index|
        @user.blood_pressure_readings.last.destroy
      end

      @user.blood_pressure_readings.last.update!(date: Date.current)
      assert_equal 1, @user.blood_pressure_readings.count
      assert_equal "130/80", WeeklyHealthSummaryPresenter.new(@user).avg_blood_pressure.combined_value
    end

    it "returns the average bp reading when multiple bp readings are present" do
      beginning_of_week = Date.current.beginning_of_week
      today = beginning_of_week + 2.days
      yesterday = today - 1.day

      @user.blood_pressure_readings.destroy_all
      [ { date: beginning_of_week, systolic: 121, diastolic: 80 },
        { date: yesterday, systolic: 130, diastolic: 92 },
        { date: today, systolic: 115, diastolic: 75 }  ].each do |bp|
          @user.blood_pressure_readings.create!(date: bp[:date], systolic: bp[:systolic], diastolic: bp[:diastolic])
        end

      # Separately averages all systolic readings, and then all diastolic readings
      assert_equal "122/82", WeeklyHealthSummaryPresenter.new(@user).avg_blood_pressure.combined_value
    end
  end

  describe "#calorie_diff" do
    it "returns nil if the user has opted out of calorie tracking" do
      @user.calorie_tracking_enabled = false
      assert_nil WeeklyHealthSummaryPresenter.new(@user).calorie_diff
    end

    it "returns nil if there are no food entries" do
      @user.food_entries.destroy_all
      assert_nil WeeklyHealthSummaryPresenter.new(@user).calorie_diff
    end

    it "returns nil if there are no food entries from last week" do
      @user.food_entries.update_all(date: Date.current)
      assert_nil WeeklyHealthSummaryPresenter.new(@user).calorie_diff
    end

    it "returns nil if there are no calorie entries for this week" do
      @user.food_entries.update_all(date: Date.current.beginning_of_week - 1.day)
      assert_nil WeeklyHealthSummaryPresenter.new(@user).calorie_diff
    end

    it "subtracts this week's average daily calorie intake from the previous week's" do
      beginning_of_week = Date.current.beginning_of_week
      today = beginning_of_week + 1.day
      yesterday = today - 1.day
      last_week_day_1 = beginning_of_week - 3.days
      last_week_day_2 = beginning_of_week - 1.day

      [ { date: last_week_day_1, name: "Banana", calories: 100 },
        { date: last_week_day_1, name: "Popsicle", calories: 300 },
        { date: last_week_day_2, name: "Hot Dogs", calories: 670 },
        { date: last_week_day_2, name: "Fruit Cup", calories: 60 },
        { date: yesterday, name: "Burger", calories: 590 },
        { date: yesterday, name: "Fries", calories: 430 },
        { date: yesterday, name: "Soda", calories: 150 },
        { date: today, name: "Fish", calories: 340 },
        { date: today, name: "Fries", calories: 430 } ].each do |entry|
          @user.food_entries.create!(date: entry[:date], name: entry[:name], calories: entry[:calories])
        end

      assert_equal 405, WeeklyHealthSummaryPresenter.new(@user).calorie_diff
    end
  end

  describe "#days_logged" do
    before do
      @week_start = Date.current.beginning_of_week
      @monday     = @week_start + 1.day
      @tuesday    = @monday + 1.day
      @wednesday  = @tuesday + 1.day

      @user.food_entries.destroy_all
      @user.weight_entries.destroy_all
      @user.blood_pressure_readings.destroy_all

      @user.food_entries.create!(date: @monday, name: "Banana", calories: 100)
      @user.weight_entries.create!(date: @tuesday, weight: 179.2)
      @user.blood_pressure_readings.create!(date: @wednesday, systolic: 115, diastolic: 75)
    end

    it "counts all days with either a food_entry, weight_entry, or blood_pressure_reading" do
      assert_equal 3, WeeklyHealthSummaryPresenter.new(@user).days_logged
    end

    it "ignores food entries if the user has calorie tracking disabled" do
      @user.calorie_tracking_enabled = false
      assert_equal 2, WeeklyHealthSummaryPresenter.new(@user).days_logged
    end

    it "ignores weight_entires if the user has weight tracking disabled" do
      @user.weight_tracking_enabled = false
      assert_equal 2, WeeklyHealthSummaryPresenter.new(@user).days_logged
    end

    it "ignores blood_pressure_readings if user has blood pressure tracking disabled" do
      @user.blood_pressure_tracking_enabled = false
      assert_equal 2, WeeklyHealthSummaryPresenter.new(@user).days_logged
    end

    it "only counts distinct dates across all records" do
      @user.food_entries.create!(date: @tuesday, name: "Burger", calories: 560)
      @user.weight_entries.create!(date: @monday, weight: 180)
      assert_equal 3, WeeklyHealthSummaryPresenter.new(@user).days_logged
    end
  end

  describe "#weekly_tips" do
    it "includes perfectly_logged_week_tip when all days have a record" do
      presenter = WeeklyHealthSummaryPresenter.new(@user)
      presenter.stubs(:days_logged).returns(7)
      expected_message = "Perfect week! All 7 days logged. Consistent data entry makes trends much more reliable."

      assert_includes presenter.weekly_tips, expected_message
    end

    it "excludes perfectly_logged_week_tip if not all days have a record" do
      presenter = WeeklyHealthSummaryPresenter.new(@user)
      presenter.stubs(:days_logged).returns(6)
      assert_not_includes presenter.weekly_tips, "Perfect week! All 7 days logged. Consistent data entry makes trends much more reliable."
    end

    it "includes bp_elevation_tip when bp is above the normal range" do
      klass = BloodPressureReading
      today = Date.current
      [
        klass.new(user: @user, date: today, systolic: klass::SYSTOLIC_ELEVATED_RANGE.last, diastolic: klass::DIASTOLIC_NORMAL_RANGE.last),
        klass.new(user: @user, date: today, systolic: klass::SYSTOLIC_STAGE_ONE_RANGE.first, diastolic: klass::DIASTOLIC_STAGE_ONE_RANGE.first),
        klass.new(user: @user, date: today, systolic: klass::SYSTOLIC_STAGE_TWO_RANGE.first, diastolic: klass::DIASTOLIC_STAGE_TWO_RANGE.first)
      ].each do |bp_category|
        presenter = WeeklyHealthSummaryPresenter.new(@user)
        presenter.stubs(:avg_blood_pressure).returns(bp_category)

        assert_includes presenter.weekly_tips, "Your average blood pressure this week (#{bp_category.combined_value}) is in the #{bp_category.category} range. Worth discussing with your doctor if this persists."
      end
    end

    it "excludes bp_elevation_tip when user has opted out of blood pressure tracking" do
      @user.blood_pressure_tracking_enabled = false
      assert WeeklyHealthSummaryPresenter.new(@user).weekly_tips.none? { |tip| tip.include?("Your average blood pressure this week") }
    end

    it "excludes bp_elevation_tip when user has no blood pressure readings" do
      @user.blood_pressure_readings.destroy_all
      assert WeeklyHealthSummaryPresenter.new(@user).weekly_tips.none? { |tip| tip.include?("Your average blood pressure this week") }
    end

    it "excludes bp_elevation_tip when blood pressure average is in the normal range" do
      klass = BloodPressureReading
      today = Date.current
      normal_reading = klass.new(user: @user, date: today, systolic: klass::SYSTOLIC_NORMAL_RANGE.last, diastolic: klass::DIASTOLIC_NORMAL_RANGE.last)

      presenter = WeeklyHealthSummaryPresenter.new(@user)
      presenter.stubs(:avg_blood_pressure).returns(normal_reading)

      assert presenter.weekly_tips.none? { |tip| tip.include?("Your average blood pressure this week") }
    end

    it "includes calorie_variance_tip when food entries are present" do
      monday    = Date.current.beginning_of_week
      tuesday   = monday + 1.day
      wednesday = tuesday + 1.day
      thursday  = wednesday + 1.day

      @user.food_entries.destroy_all
      [
        { name: "Banana", calories: 100, date: monday },
        { name: "Watermelon", calories: 45, date: tuesday },
        { name: "Tacos", calories: 580, date: wednesday },
        { name: "Pizza", calories: 3_000, date: thursday }
      ].each do |entry|
        @user.food_entries.create!(name: entry[:name], calories: entry[:calories], date: entry[:date])
      end

      presenter = WeeklyHealthSummaryPresenter.new(@user)
      assert presenter.weekly_tips.any? { |tip| tip.include?("Your daily calories varied quite a bit this week") }
    end

    it "excludes calorie_variance_tip when user has opted out of calorie tracking" do
      @user.calorie_tracking_enabled = false
      assert WeeklyHealthSummaryPresenter.new(@user).weekly_tips.none? { |tip| tip.include?("Your daily calories varied quite a bit this week") }
    end

    it "excludes calorie_variance_tip when user has less than 4 food entries" do
      @user.food_entries.destroy_all
      @user.food_entries.create!(date: Date.current, name: "Banana", calories: 100)

      assert WeeklyHealthSummaryPresenter.new(@user).weekly_tips.none? { |tip| tip.include?("Your daily calories varied quite a bit this week") }
    end

    it "excludes calorie_variance_tip when the standard deviation of a user's daily calorie intake is less than 400" do
            monday    = Date.current.beginning_of_week
      tuesday   = monday + 1.day
      wednesday = tuesday + 1.day
      thursday  = wednesday + 1.day

      @user.food_entries.destroy_all
      [
        { name: "Banana", calories: 100, date: monday },
        { name: "Watermelon", calories: 200, date: tuesday },
        { name: "Tacos", calories: 300, date: wednesday },
        { name: "Pizza", calories: 200, date: thursday }
      ].each do |entry|
        @user.food_entries.create!(name: entry[:name], calories: entry[:calories], date: entry[:date])
      end

      presenter = WeeklyHealthSummaryPresenter.new(@user)
      assert presenter.weekly_tips.none? { |tip| tip.include?("Your daily calories varied quite a bit this week") }
    end

    it "includes the logging_streak_improved_tip when the number of logged days this week is greater than the number of logged days last week" do
      presenter = WeeklyHealthSummaryPresenter.new(@user)
      presenter.stubs(:days_logged).returns(2)
      presenter.previous_week.stubs(:days_logged).returns(1)

      assert presenter.weekly_tips.any? { |tip| tip.include?("You logged more days than last week") }
    end

    it "excludes the logging_streak_improved_tip when the number of days logged this week are less than the number of days logged last week" do
      presenter = WeeklyHealthSummaryPresenter.new(@user)
      presenter.stubs(:days_logged).returns(1)
      presenter.previous_week.stubs(:days_logged).returns(2)

      assert presenter.weekly_tips.none? { |tip| tip.include?("You logged more days than last week") }
    end
  end
end
