class User < ApplicationRecord
  DEFAULT_DAILY_CALORIE_GOAL = 2_000
  VALID_TIMEZONES = ActiveSupport::TimeZone.all.map(&:tzinfo).map(&:name).freeze

  using Refinements::ArrayRefinements

  has_secure_password

  has_many :sessions,       dependent: :destroy
  has_many :food_entries,   dependent: :destroy
  has_many :weight_entries, dependent: :destroy
  has_many :blood_pressure_readings, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :daily_calorie_goal, presence: true, numericality: { greater_than: 0 }
  validates :timezone,           presence: true, inclusion: { in: VALID_TIMEZONES }
  validates :calorie_tracking_enabled,           inclusion: { in: [ true, false ], message: "value must be true or false" }
  validates :weight_tracking_enabled,            inclusion: { in: [ true, false ], message: "value must be true or false" }
  validates :blood_pressure_tracking_enabled,    inclusion: { in: [ true, false ], message: "value must be true or false" }

  alias_attribute :email, :email_address

  def days_over_budget
    food_entries
      .group(:date)
      .sum(:calories)
      .select { |date, total_calories| total_calories > daily_calorie_goal }
      .count
  end

  def lifetime_calorie_deficit
    (food_entries.pluck(:date).uniq.count * DEFAULT_DAILY_CALORIE_GOAL) - food_entries.sum(:calories)
  end

  def median_calories_consumed
    food_entries.group(:date).sum(:calories).values.median
  end

  def min_recorded_weight
    weight_entries.min_by(&:weight)&.weight
  end

  def max_recorded_weight
    weight_entries.max_by(&:weight)&.weight
  end

  def current_weight
    weight_entries.max_by(&:date)&.weight
  end

  def calorie_tracking_disabled?
    !calorie_tracking_enabled?
  end

  def weight_tracking_disabled?
    !weight_tracking_enabled?
  end

  def blood_pressure_tracking_disabled?
    !blood_pressure_tracking_enabled?
  end

  def all_features_disabled?
    calorie_tracking_disabled? &&
      weight_tracking_disabled? &&
        blood_pressure_tracking_disabled?
  end
end
