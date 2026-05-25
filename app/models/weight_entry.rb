class WeightEntry < ApplicationRecord
  belongs_to :user, optional: false

  validates :weight, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :date,   presence: true
end
