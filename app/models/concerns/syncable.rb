module Syncable
  extend ActiveSupport::Concern

  included do
    before_validation :assign_uuid, on: :create
    after_destroy :record_deletion
  end

  def sync_type
    self.class.name.underscore
  end

  def sync_owner_id
    user_id
  end

  private

  def assign_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def record_deletion
    Deletion.create!(user_id: sync_owner_id, record_type: sync_type, uuid: uuid, deleted_at: Time.current)
  end
end
