# frozen_string_literal: true

class BloodPressureReading < ApplicationRecord
  include Comparable

  SYSTOLIC_NORMAL_RANGE     = (..119)
  SYSTOLIC_ELEVATED_RANGE   = (120..129)
  SYSTOLIC_STAGE_ONE_RANGE  = (130..139)
  SYSTOLIC_STAGE_TWO_RANGE  = (140..)

  DIASTOLIC_NORMAL_RANGE    = (..79)
  DIASTOLIC_STAGE_ONE_RANGE = (80..89)
  DIASTOLIC_STAGE_TWO_RANGE = (90..)

  NORMAL_BLOOD_PRESSURE   = "Normal Blood Pressure"
  ELEVATED_BLOOD_PRESSURE = "Elevated Blood Pressure"
  STAGE_ONE_HYPERTENSION  = "Stage 1 Hypertension"
  STAGE_TWO_HYPERTENSION  = "Stage 2 Hypertension"

  belongs_to :user, optional: false

  validates :systolic,  presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :diastolic, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :date,      presence: true, uniqueness: { scope: :user_id, message: "already has a blood pressure reading" }

  def category
    if stage_two?
      STAGE_TWO_HYPERTENSION
    elsif stage_one?
      STAGE_ONE_HYPERTENSION
    elsif elevated?
      ELEVATED_BLOOD_PRESSURE
    else
      NORMAL_BLOOD_PRESSURE
    end
  end

  def label
    "#{combined_value} mm Hg"
  end

  def combined_value
    "#{systolic}/#{diastolic}"
  end

  # Mean Arterial Pressure Score
  def map_score
    diastolic + (systolic - diastolic) / 3.0
  end

  def <=>(other)
    map_score <=> other.map_score
  end

  def normal?
    SYSTOLIC_NORMAL_RANGE.include?(systolic) &&
      DIASTOLIC_NORMAL_RANGE.include?(diastolic)
  end

  def elevated?
    SYSTOLIC_ELEVATED_RANGE.include?(systolic) &&
      DIASTOLIC_NORMAL_RANGE.include?(diastolic)
  end

  def stage_one?
    return false if stage_two?

    SYSTOLIC_STAGE_ONE_RANGE.include?(systolic) ||
      DIASTOLIC_STAGE_ONE_RANGE.include?(diastolic)
  end

  def stage_two?
    SYSTOLIC_STAGE_TWO_RANGE.include?(systolic) ||
      DIASTOLIC_STAGE_TWO_RANGE.include?(diastolic)
  end
end
