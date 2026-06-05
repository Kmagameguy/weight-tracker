class FoodEntry < ApplicationRecord
  belongs_to :user, optional: false

  validates :name,     presence: true
  validates :calories, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :date,     presence: true

  alias_attribute :consumed_on, :date
end
