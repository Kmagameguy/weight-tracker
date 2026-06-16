require "test_helper"

class BloodPressureReadingTest < ActiveSupport::TestCase
  setup { @subject = BloodPressureReading }

  describe "constants" do
    it "exposes the SYSTOLIC_NORMAL_RANGE constant" do
      assert defined?(@subject::SYSTOLIC_NORMAL_RANGE)
      assert_equal (..119), @subject::SYSTOLIC_NORMAL_RANGE
    end

    it "exposes the SYSTOLIC_ELEVATED_RANGE constant" do
      assert defined?(@subject::SYSTOLIC_ELEVATED_RANGE)
      assert_equal (120..129), @subject::SYSTOLIC_ELEVATED_RANGE
    end

    it "exposes the SYSTOLIC_STAGE_ONE_RANGE constant" do
      assert defined?(@subject::SYSTOLIC_STAGE_ONE_RANGE)
      assert_equal (130..139), @subject::SYSTOLIC_STAGE_ONE_RANGE
    end

    it "exposes the SYSTOLIC_STAGE_TWO_RANGE constant" do
      assert defined?(@subject::SYSTOLIC_STAGE_TWO_RANGE)
      assert_equal (140..), @subject::SYSTOLIC_STAGE_TWO_RANGE
    end

    it "exposes the DIASTOLIC_NORMAL_RANGE constant" do
      assert defined?(@subject::DIASTOLIC_NORMAL_RANGE)
      assert_equal (..79), @subject::DIASTOLIC_NORMAL_RANGE
    end

    it "exposes the DIASTOLIC_STAGE_ONE_RANGE constant" do
      assert defined?(@subject::DIASTOLIC_STAGE_ONE_RANGE)
      assert_equal (80..89), @subject::DIASTOLIC_STAGE_ONE_RANGE
    end

    it "exposes the DIASTOLIC_STAGE_TWO_RANGE constant" do
      assert defined?(@subject::DIASTOLIC_STAGE_TWO_RANGE)
      assert_equal (90..), @subject::DIASTOLIC_STAGE_TWO_RANGE
    end

    it "exposes the NORMAL_BLOOD_PRESSURE constant" do
      assert defined?(@subject::NORMAL_BLOOD_PRESSURE)
      assert_equal "Normal Blood Pressure", @subject::NORMAL_BLOOD_PRESSURE
    end

    it "exposes the ELEVATED_BLOOD_PRESSURE constant" do
      assert defined?(@subject::ELEVATED_BLOOD_PRESSURE)
      assert_equal "Elevated Blood Pressure", @subject::ELEVATED_BLOOD_PRESSURE
    end

    it "exposes the STAGE_ONE_HYPERTENSION constant" do
      assert defined?(@subject::STAGE_ONE_HYPERTENSION)
      assert_equal "Stage 1 Hypertension", @subject::STAGE_ONE_HYPERTENSION
    end

    it "exposes the STAGE_TWO_HYPERTENSION constant" do
      assert defined?(@subject::STAGE_TWO_HYPERTENSION)
      assert_equal "Stage 2 Hypertension", @subject::STAGE_TWO_HYPERTENSION
    end
  end

  describe "validations" do
    before { @reading = blood_pressure_readings(:normal) }

    it "is valid with valid attributes" do
      reading = BloodPressureReading.new(
        systolic: 119,
        diastolic: 79,
        date: Date.current,
        user: users(:one)
      )

      assert_predicate reading, :valid?
    end

    it "is invalid without a systolic value" do
      @reading.systolic = nil

      assert_not_predicate @reading, :valid?
      assert_includes @reading.errors[:systolic], "can't be blank"
    end

    it "is invalid with a negative systolic value" do
      @reading.systolic = -1

      assert_not_predicate @reading, :valid?
      assert_includes @reading.errors[:systolic], "must be greater than or equal to 0"
    end

    it "is invalid without a diastolic value" do
      @reading.diastolic = nil

      assert_not_predicate @reading, :valid?
      assert_includes @reading.errors[:diastolic], "can't be blank"
    end

    it "is invalid with a negative diastolic value" do
      @reading.diastolic = -1

      assert_not_predicate @reading, :valid?
      assert_includes @reading.errors[:diastolic], "must be greater than or equal to 0"
    end

    it "is invalid without a date" do
      @reading.date = nil

      assert_not_predicate @reading, :valid?
      assert_includes @reading.errors[:date], "can't be blank"
    end

    it "is invalid if an existing blood pressure reading exists for the given date" do
      new_reading = BloodPressureReading.new(
        systolic: 120,
        diastolic: 80,
        date: @reading.date,
        user: users(:one)
      )

      assert_not_predicate new_reading, :valid?
      assert_includes new_reading.errors[:date], "already has a blood pressure reading"
    end

    it "is invalid without a user" do
      @reading.user = nil

      assert_not_predicate @reading, :valid?
      assert_includes @reading.errors[:user], "must exist"
    end
  end

  describe "#category" do
    before { @reading = blood_pressure_readings(:normal) }

    it "returns STAGE_TWO_HYPERTENSION when stage two" do
      @reading.stubs(:stage_two?).returns(true)

      assert_equal @subject::STAGE_TWO_HYPERTENSION, @reading.category
    end

    it "returns STAGE_ONE_HYPERTENSION when stage one" do
      @reading.stubs(:stage_one?).returns(true)

      assert_equal @subject::STAGE_ONE_HYPERTENSION, @reading.category
    end

    it "returns ELEVATED_BLOOD_PRESSURE when elevated" do
      @reading.stubs(:elevated?).returns(true)

      assert_equal @subject::ELEVATED_BLOOD_PRESSURE, @reading.category
    end

    it "returns NORMAL_BLOOD_PRESSURE when normal" do
      assert_equal @subject::NORMAL_BLOOD_PRESSURE, @reading.category
    end
  end

  describe "#label" do
    it "concatenates the systolic and diastolic values with a mm Hg unit" do
      assert_equal "119/79 mm Hg", blood_pressure_readings(:normal).label
    end
  end

  describe "#combined_value" do
    it "concatenates the systolic and diastolic values" do
      assert_equal "119/79", blood_pressure_readings(:normal).combined_value
    end
  end

  describe "#normal?" do
    before { @reading = blood_pressure_readings(:normal) }

    it "returns true when the systolic and diastolic values are in the normal range" do
      assert_predicate @reading, :normal?
    end

    it "returns false if the systolic value is out of range" do
      @reading.update!(systolic: @subject::SYSTOLIC_NORMAL_RANGE.max + 1)

      assert_not_predicate @reading, :normal?
    end

    it "returns false if the diastolic cvalue is out of range" do
      @reading.update!(diastolic: @subject::DIASTOLIC_NORMAL_RANGE.max + 1)

      assert_not_predicate @reading, :normal?
    end

    it "returns false if the systolic and diastolic values are out of range" do
      @reading.update!(
        systolic: @subject::SYSTOLIC_NORMAL_RANGE.max + 1,
        diastolic: @subject::DIASTOLIC_NORMAL_RANGE.max + 1
      )

      assert_not_predicate @reading, :normal?
    end
  end

  describe "#elevated?" do
    before { @reading = blood_pressure_readings(:normal) }

    it "returns true when the systolic and diastolic values are in the elevated range" do
      @reading.update!(
        systolic: @subject::SYSTOLIC_ELEVATED_RANGE.min,
        diastolic: @subject::DIASTOLIC_NORMAL_RANGE.max
      )

      assert_predicate @reading, :elevated?
    end

    it "returns false if the systolic and diastolic values are under the range" do
      assert_not_predicate @reading, :elevated?
    end

    it "returns false if the systolic value is above the range" do
      @reading.update!(systolic: @subject::SYSTOLIC_ELEVATED_RANGE.max + 1)

      assert_not_predicate @reading, :elevated?
    end

    it "returns false if the diastolic value is above the range" do
      @reading.update!(diastolic: @subject::DIASTOLIC_NORMAL_RANGE.max + 1)

      assert_not_predicate @reading, :elevated?
    end

    it "returns false if the systolic and diastolic values are above the range" do
      @reading.update!(
        systolic: @subject::SYSTOLIC_ELEVATED_RANGE.max + 1,
        diastolic: @subject::DIASTOLIC_NORMAL_RANGE.max + 1
      )

      assert_not_predicate @reading, :elevated?
    end
  end

  describe "#stage_one?" do
    it "returns true when the systolic and diastolic values are in the range" do
      reading = blood_pressure_readings(:stage_1_both)
      assert_predicate reading, :stage_one?
    end

    it "returns true when only the systolic value is in the range" do
      reading = blood_pressure_readings(:stage_1_systolic)
      assert_predicate reading, :stage_one?
    end

    it "returns true when only the diastolic value is in the range" do
      reading = blood_pressure_readings(:stage_1_diastolic)
      assert_predicate reading, :stage_one?
    end

    it "returns false when the systolic and diastolic values are below the range" do
      reading = blood_pressure_readings(:normal)
      assert_not_predicate reading, :stage_one?
    end

    it "returns false when the systolic and diastolic values are above the range" do
      reading = blood_pressure_readings(:stage_2_both)
      assert_not_predicate reading, :stage_one?
    end

    it "returns false when only the systolic value is above the range" do
      reading = blood_pressure_readings(:stage_1_both)
      reading.update!(systolic: @subject::SYSTOLIC_STAGE_ONE_RANGE.max + 1)

      assert_not_predicate reading, :stage_one?
    end

    it "returns false when only the diastolic value is above the range" do
      reading = blood_pressure_readings(:stage_1_both)
      reading.update!(diastolic: @subject::DIASTOLIC_STAGE_ONE_RANGE.max + 1)

      assert_not_predicate reading, :stage_one?
    end
  end

  describe "#stage_two?" do
    it "returns true when the systolic and diastolic values are in the range" do
      reading = blood_pressure_readings(:stage_2_both)

      assert_predicate reading, :stage_two?
    end

    it "returns true when only the systolic value is in the range" do
      reading = blood_pressure_readings(:stage_2_systolic)

      assert_predicate reading, :stage_two?
    end

    it "returns true when only the diastolic value is in the range" do
      reading = blood_pressure_readings(:stage_2_diastolic)

      assert_predicate reading, :stage_two?
    end

    it "returns false when the systolic and diastolic values are below the range" do
      reading = blood_pressure_readings(:stage_1_both)

      assert_not_predicate reading, :stage_two?
    end
  end
end
