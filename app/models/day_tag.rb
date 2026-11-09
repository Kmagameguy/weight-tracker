class DayTag < ApplicationRecord
  include Syncable

  belongs_to :tag, optional: false

  validates :date, presence: true, uniqueness: { scope: :tag_id }

  def sync_owner_id
    tag.user_id
  end
end
