class Tag < ApplicationRecord
  include Syncable

  MAX_NAME_LENGTH = 30

  syncs :name, unique_by: lambda { |scope, attrs|
    normalized = Tag.normalize_value_for(:name, attrs["name"].to_s)
    scope.find_by("LOWER(name) = ?", normalized.downcase)
  }

  belongs_to :user, optional: false
  has_many :day_tags, dependent: :destroy

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true,
                   length: { maximum: MAX_NAME_LENGTH },
                   uniqueness: { scope: :user_id, case_sensitive: false, message: "already exists" }
end
