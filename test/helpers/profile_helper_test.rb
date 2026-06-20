require "test_helper"

class ProfileHelperTest < ActionView::TestCase
  helper ProfileHelper

  describe "#number_to_sequence" do
    it "returns 'once' when 1" do
      assert_equal "once", number_to_sequence(1)
    end

    it "returns 'twice' when 2" do
      assert_equal "twice", number_to_sequence(2)
    end

    it "returns 'x times' for values 3 and above" do
      [ 3, 4, 5, 27, 120 ].each do |val|
        assert_equal "#{val} times", number_to_sequence(val)
      end
    end

    it "returns '0 times' when 0" do
      assert_equal "0 times", number_to_sequence(0)
    end

    it "returns an empty string when the value is empty" do
      [ nil, [], {}, "" ].each do |val|
        assert_equal("", number_to_sequence(val))
      end
    end

    it "returns an empty string when the value cannot be cast to an integer" do
      assert_equal("", number_to_sequence(Date::Infinity))
    end
  end

  describe "#avg_daily_calories_label" do
    it "returns a blank entry template when value is blank" do
      assert_equal blank_entry, avg_daily_calories_label(nil)
    end

    it "formats number with delimiter" do
      assert_match "2,000", avg_daily_calories_label(2000)
    end

    it "includes kcal label" do
      assert_match "kcal", avg_daily_calories_label(2000)
    end
  end

  describe "#calorie_diff_label" do
    it "returns nothing if the diff is blank" do
      [ "", nil, [], {} ].each do |val|
        assert_nil calorie_diff_label(val)
      end
    end

    it "computes the difference between the current and previous week's average calorie intake" do
      assert_match "+1,000 vs last week", calorie_diff_label(1000)
    end

    it "indicates no change when value is zero" do
      assert_match "no change vs last week", calorie_diff_label(0)
    end

    it "handles negative values correctly" do
      assert_match "-500 vs last week", calorie_diff_label(-500)
    end
  end

  describe "#weight_change_label" do
    it "returns a blank entry template when the value is blank" do
      assert_equal blank_entry, weight_change_label(nil)
    end

    it "formats a positive number correctly" do
      assert_match "+100", weight_change_label(100)
    end

    it "formats a negative number correctly" do
      assert_match "-100", weight_change_label(-100)
    end

    it "formats zero correctly" do
      assert_match "0", weight_change_label(0)
    end

    it "includes the weight unit" do
      assert_match "lbs", weight_change_label(20)
    end
  end

  describe "#weight_change_diff" do
    it "returns nothing if there's no weight change" do
      [ nil, [], {}, "" ].each do |val|
        assert_nil weight_change_diff(val)
      end
    end

    it "returns '↓ trending down' when the weight change is negative" do
      assert_match "↓ trending down", weight_change_diff(-100)
    end

    it "returns 'no change' when weight stayed the same" do
      assert_match "no change", weight_change_diff(0)
    end

    it "returns '↑ trending up' when the weight change is positive" do
      assert_match "↑ trending up", weight_change_diff(100)
    end
  end

  describe "#avg_blood_pressure_label" do
    it "returns a blank entry when the value is blank" do
      assert_equal blank_entry, avg_blood_pressure_label(nil)
    end

    it "formats the avg blood pressure text correctly" do
      assert_match "120/82  <span class=\"text-xs font-normal text-slate-400\">mmHg</span",
        avg_blood_pressure_label(BloodPressureReading.new(date: Date.current, systolic: 120, diastolic: 82))
    end
  end

  describe "#blood_pressure_diff" do
    it "returns nothing if current bp is blank" do
      prev_bp = BloodPressureReading.new
      [ nil, "", [], {} ].each do |val|
        assert_nil blood_pressure_diff(val, prev_bp)
      end
    end

    it "returns nothing if previous bp is blank" do
      current_bp = BloodPressureReading.new
      [ nil, "", [], {} ].each do |val|
        assert_nil blood_pressure_diff(current_bp, val)
      end
    end

    it "returns '↓ trending down' when the avg bp is lower" do
      current_bp = BloodPressureReading.new(date: Date.current, systolic: 120, diastolic: 80)
      old_bp = BloodPressureReading.new(date: Date.current - 1.week, systolic: 130, diastolic: 82)

      assert_match "↓ trending down", blood_pressure_diff(current_bp, old_bp)
    end

    it "returns 'no change' when avg bp stayed the same" do
      current_bp = BloodPressureReading.new(date: Date.current, systolic: 120, diastolic: 80)
      old_bp = BloodPressureReading.new(date: Date.current - 1.week, systolic: 120, diastolic: 80)

      assert_match "no change", blood_pressure_diff(current_bp, old_bp)
    end

    it "returns '↑ trending up' when the avg bp is higher" do
      current_bp = BloodPressureReading.new(date: Date.current, systolic: 120, diastolic: 80)
      old_bp = BloodPressureReading.new(date: Date.current - 1.week, systolic: 115, diastolic: 78)

      assert_match "↑ trending up", blood_pressure_diff(current_bp, old_bp)
    end
  end

  describe "#blank_entry" do
    it "returns a blank <p> element" do
      assert_equal "<p class=\"text-2xl font-medium text-slate-200\">—</p>", blank_entry
    end
  end
end
