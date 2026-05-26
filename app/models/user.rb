class User < ApplicationRecord
  has_secure_password

  has_many :sessions,       dependent: :destroy
  has_many :food_entries,   dependent: :destroy
  has_many :weight_entries, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :daily_calorie_goal, presence: true, numericality: { greater_than: 0 }

  alias_attribute :email, :email_address
end
