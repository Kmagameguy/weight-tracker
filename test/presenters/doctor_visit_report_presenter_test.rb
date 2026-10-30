# frozen_string_literal: true

require "test_helper"

class DoctorVisitReportPresenterTest < ActiveSupport::TestCase
  setup do
    @user  = users(:one)
    @start = Date.new(2026, 5, 25)
    @end   = Date.new(2026, 6, 5)

    @user.food_entries.destroy_all
    @user.food_entries.create!(date: @start, name: "Burrito", calories: 1_000)

    @user.weight_entries.destroy_all
    @user.weight_entries.create!(date: @start - 1.day, weight: 300.0)
    @user.weight_entries.create!(date: @start, weight: 200.0)
    @user.weight_entries.create!(date: @start + 3.days, weight: 197.5)

    @user.blood_pressure_readings.destroy_all
    [
      [ 0, 121, 80 ],
      [ 1, 130, 92 ],
      [ 2, 115, 75 ]
    ].each do |offset, systolic, diastolic|
      @user.blood_pressure_readings.create!(date: @start + offset.days, systolic: systolic, diastolic: diastolic)
    end
  end

  def build_presenter(**options)
    DoctorVisitReportPresenter.new(user: @user, start_date: @start, end_date: @end, **options)
  end

  describe "#day_count" do
    it "counts both ends of the range" do
      assert_equal 12, build_presenter.day_count
    end
  end

  describe "#include_calories?" do
    before { @user.calorie_tracking_enabled = true }

    it "is true by default" do
      assert_predicate build_presenter, :include_calories?
    end

    it "is false when opted-out" do
      assert_not_predicate build_presenter(include_calories: false), :include_calories?
    end

    it "is false when requested but the user has calorie tracking disabled" do
      @user.calorie_tracking_enabled = false

      assert_not_predicate build_presenter(include_calories: true), :include_calories?
    end
  end

  describe "#include_weights?" do
    before { @user.weight_tracking_enabled = true }

    it "is true by default" do
      assert_predicate build_presenter, :include_weights?
    end

    it "is false when opted-out" do
      assert_not_predicate build_presenter(include_weights: false), :include_weights?
    end

    it "is false when requested but the user has weight tracking disabled" do
      @user.weight_tracking_enabled = false

      assert_not_predicate build_presenter(include_weights: true), :include_weights?
    end
  end

  describe "#include_blood_pressure_readings?" do
    before { @user.blood_pressure_tracking_enabled = true }

    it "is true by default" do
      assert_predicate build_presenter, :include_blood_pressure_readings?
    end

    it "is false when opted-out" do
      assert_not_predicate build_presenter(include_blood_pressure_readings: false), :include_blood_pressure_readings?
    end

    it "is false when requested but the user has blood pressure tracking disabled" do
      @user.blood_pressure_tracking_enabled = false

      assert_not_predicate build_presenter(include_blood_pressure_readings: true), :include_blood_pressure_readings?
    end
  end

  describe "#include_tags?" do
    before { @user.tagging_enabled = true }

    it "is true by default" do
      assert_predicate build_presenter, :include_tags?
    end

    it "is false when opted-out" do
      assert_not_predicate build_presenter(include_tags: false), :include_tags?
    end

    it "is false when requested but the user has tagging disabled" do
      @user.tagging_enabled = false

      assert_not_predicate build_presenter(include_tags: true), :include_tags?
    end
  end

  describe "#include_journal?" do
    before { @user.journaling_enabled = true }

    it "is false by default" do
      assert_not_predicate build_presenter, :include_journal?
    end

    it "is true when requested" do
      assert_predicate build_presenter(include_journal: true), :include_journal?
    end

    it "is false when requested but the user has journaling disabled" do
      @user.journaling_enabled = false

      assert_not_predicate build_presenter(include_journal: true), :include_journal?
    end
  end

  describe "#blank?" do
    it "is true when the user has all features disabled" do
      @user.assign_attributes(
        calorie_tracking_enabled: false,
        weight_tracking_enabled: false,
        blood_pressure_tracking_enabled: false,
        tagging_enabled: false,
        journaling_enabled: false
      )

      assert_predicate build_presenter, :blank?
    end

    it "is true when the user has not selected any report options" do
      @user.calorie_tracking_enabled = true
      assert_predicate(
        build_presenter(
          include_calories: false,
          include_weights: false,
          include_blood_pressure_readings: false,
          include_tags: false,
          include_journal: false
        ),
        :blank?
      )
    end

    it "is false when at least one section is eligible for display" do
      @user.calorie_tracking_enabled = true

      assert_not_predicate build_presenter, :blank?
    end
  end

  describe "#days_logged" do
    it "counts distinct days with any entry across features" do
      # entries created above + fixtures
      assert_equal 5, build_presenter.days_logged
    end

    it "ignores disabled features" do
      @user.assign_attributes(calorie_tracking_enabled: false, weight_tracking_enabled: false, journaling_enabled: false)

      assert_equal 4, build_presenter.days_logged
    end
  end

  describe "#average_daily_calories" do
    it "averages calories across logged days" do
      assert_equal 1_000, build_presenter.avg_daily_calories
    end

    it "is nil without food entries" do
      @user.food_entries.destroy_all

      assert_nil build_presenter.avg_daily_calories
    end
  end

  describe "#days_over_goal" do
    it "counts the number of days where the calorie intake was above the user's defined daily goal" do
      @user.food_entries.create!(name: "Pizza", calories: 2_500, date: @start)

      assert_equal 1, build_presenter.days_over_goal
    end
  end

  describe "#days_at_or_under_goal" do
    it "counts the number of days where the calorie intake was less-than-or-equal-to the user's defined daily goal" do
      @user.food_entries.destroy_all
      @user.food_entries.create!(name: "Pizza", calories: 1_500, date: @start)
      @user.food_entries.create!(name: "Soup", calories: 800, date: @start + 1.day)
      @user.food_entries.create!(name: "Burger", calories: 1650, date: @start + 2.days)

      assert_equal 2, build_presenter.days_at_or_under_goal
    end
  end

  describe "#highest_calorie_day" do
    it "finds the day within the range with the highest calorie intake" do
      highest_entry = @user.food_entries.create!(name: "Pizza", calories: 1_600, date: @start + 2.days)

      assert_operator @user.food_entries.map(&:date).uniq.count, :>, 1
      assert_equal highest_entry.date, build_presenter.highest_calorie_day.first
    end
  end

  describe "#weight_change" do
    it "calculates the change from start_date to end_date" do
      assert_equal -2.5, build_presenter.weight_change
    end

    it "is nil when there are less than 2 entries" do
      @user.weight_entries.where(date: @start + 3.days).destroy_all
      assert_nil build_presenter.weight_change
    end
  end

  describe "#min_weight" do
    it "finds the minimum weight entry" do
      assert_equal 197.5, build_presenter.min_weight
    end

    it "is nil when there are no weight entries" do
      @user.weight_entries.destroy_all

      assert_nil build_presenter.min_weight
    end
  end

  describe "#max_weight" do
    it "finds the maximum weight entry" do
      assert_equal 200.0, build_presenter.max_weight
    end

    it "is nil when there are no weight entries" do
      @user.weight_entries.destroy_all

      assert_nil build_presenter.max_weight
    end
  end

  describe "#avg_blood_pressure" do
    it "averages systolic and diastolic separately" do
      assert_equal "122/82", build_presenter.avg_blood_pressure.combined_value
    end

    it "is nil without readings" do
      @user.blood_pressure_readings.destroy_all

      assert_nil build_presenter.avg_blood_pressure
    end
  end

  describe "#most_severe_blood_pressure_reading" do
    it "is nil without readings" do
      @user.blood_pressure_readings.destroy_all

      assert_nil build_presenter.most_severe_blood_pressure_reading
    end

    it "prioritizes the highest category rank" do
      assert_equal BloodPressureReading::STAGE_TWO_HYPERTENSION, build_presenter.most_severe_blood_pressure_reading.category
    end

    it "uses systolic pressure to break category ties" do
      most_severe = @user.blood_pressure_readings.create!(date: @start + 3.days, systolic: 136, diastolic: 92)

      assert_equal most_severe, build_presenter.most_severe_blood_pressure_reading
    end

    it "uses diastolic pressure to break systolic ties" do
      most_severe = @user.blood_pressure_readings.create!(date: @start + 3.days, systolic: 130, diastolic: 93)

      assert_equal most_severe, build_presenter.most_severe_blood_pressure_reading
    end
  end

  describe "#least_severe_blood_pressure_reading" do
    it "is nil without readings" do
      @user.blood_pressure_readings.destroy_all

      assert_nil build_presenter.least_severe_blood_pressure_reading
    end

    it "prioritizes the lowest category rank" do
      assert_equal "Normal Blood Pressure", build_presenter.least_severe_blood_pressure_reading.category
    end

    it "uses systolic pressure to break category ties" do
      least_severe = @user.blood_pressure_readings.create!(date: @start + 3.days, systolic: 110, diastolic: 75)

      assert_equal least_severe, build_presenter.least_severe_blood_pressure_reading
    end

    it "uses diastolic pressure to break systolic ties" do
      least_severe = @user.blood_pressure_readings.create!(date: @start + 3.days, systolic: 115, diastolic: 74)

      assert_equal least_severe, build_presenter.least_severe_blood_pressure_reading
    end
  end

  describe "#blood_pressure_category_summaries" do
    it "returns an empty hash when there are no readings" do
      @user.blood_pressure_readings.destroy_all

      assert_equal({}, build_presenter.blood_pressure_category_summaries)
    end

    it "returns summaries for every blood pressure category" do
      @user.blood_pressure_readings.create!(date: @start + 3.days, systolic: 145, diastolic: 92)
      assert_equal(
        [
          {
            category: BloodPressureReading::NORMAL_BLOOD_PRESSURE,
            count: 1,
            percentage: 25
          },
          {
            category: BloodPressureReading::ELEVATED_BLOOD_PRESSURE,
            count: 0,
            percentage: 0
          },
          {
            category: BloodPressureReading::STAGE_ONE_HYPERTENSION,
            count: 1,
            percentage: 25
          },
          {
            category: BloodPressureReading::STAGE_TWO_HYPERTENSION,
            count: 2,
            percentage: 50
          }
        ],
        build_presenter.blood_pressure_category_summaries
      )
    end

    it "rounds percentages to the nearest whole number" do
      normal_summary = build_presenter.blood_pressure_category_summaries.find do |summary|
        summary[:category] == BloodPressureReading::NORMAL_BLOOD_PRESSURE
      end

      assert_equal 33, normal_summary[:percentage]
    end
  end

  describe "#blood_pressure_category_counts" do
    it "returns an empty hash when there are no readings" do
      @user.blood_pressure_readings.destroy_all

      assert_equal({}, build_presenter.blood_pressure_category_counts)
    end

    it "returns the count of readings grouped by category" do
      @user.blood_pressure_readings.create!(date: @start + 3.days, systolic: 145, diastolic: 92)

      assert_equal(
        {
          BloodPressureReading::NORMAL_BLOOD_PRESSURE  => 1,
          BloodPressureReading::STAGE_ONE_HYPERTENSION => 1,
          BloodPressureReading::STAGE_TWO_HYPERTENSION => 2
        },
        build_presenter.blood_pressure_category_counts
      )
    end
  end

  describe "#tags_on" do
    it "returns an empty array when there are no tags for the given date" do
      @user.tags.destroy_all

      assert_equal([], build_presenter.tags_on(@start))
    end

    it "returns tag names for the given date" do
      assert_equal [ "Headache" ], build_presenter.tags_on(@end)
    end

    it "returns tag names in alphabetical order" do
      @user.tags.create!(name: "Allergies").day_tags.create!(date: @end)

      assert_equal([ "Allergies", "Headache" ], build_presenter.tags_on(@end))
    end
  end

  describe "#tag_summaries" do
    it "summarizes tagged days" do
      tags(:headache).day_tags.create!(date: @start + 5.days)
      summary = build_presenter.tag_summaries.first

      assert_equal "Headache", summary[:name]
      assert_equal 2, summary[:days]
      assert_not_empty summary[:dates]
    end

    it "excludes tags for days outside the range" do
      tags(:headache).day_tags.create!(date: @end + 1.day)

      assert_equal 1, build_presenter.tag_summaries.first[:days]
    end

    it "excludes other users' tags" do
      users(:two).tags.first.day_tags.create!(date: @start)

      assert_equal [ "Headache" ], build_presenter.tag_summaries.map { it[:name] }
    end
  end

  describe "#journal_entries" do
    it "returns notes in the range" do
      assert_equal [ "Had a pretty great day." ], build_presenter.journal_entries.map(&:note)
    end

    it "skips blank notes" do
      @user.journal_entries.update_all(note: nil)

      assert_empty build_presenter.journal_entries
    end
  end
end
