class DayTag < ApplicationRecord
  include Syncable

  syncs :date, parent: :tag, unique_by: %i[tag_id date]

  belongs_to :tag, optional: false

  validates :date, presence: true, uniqueness: { scope: :tag_id }

  def self.owned_by(user)
    where(tag_id: Tag.where(user_id: user.id).select(:id))
  end

  def sync_owner_id
    tag.user_id
  end
end
