class DayTag < ApplicationRecord
  belongs_to :tag, optional: false

  validates :date, presence: true, uniqueness: { scope: :tag_id }
end
