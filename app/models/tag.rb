class Tag < ApplicationRecord
  MAX_NAME_LENGTH = 30

  belongs_to :user, optional: false
  has_many :day_tags, dependent: :destroy

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true,
                   length: { maximum: MAX_NAME_LENGTH },
                   uniqueness: { scope: :user_id, case_sensitive: false, message: "already exists" }
end
