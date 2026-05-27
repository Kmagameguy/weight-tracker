class User < ApplicationRecord
  using Refinements::ArrayRefinements

  has_secure_password

  has_many :sessions,       dependent: :destroy
  has_many :food_entries,   dependent: :destroy
  has_many :weight_entries, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :daily_calorie_goal, presence: true, numericality: { greater_than: 0 }

  alias_attribute :email, :email_address

  def median_calories_consumed
    food_entries.group(:date).sum(:calories).values.median
  end
end
