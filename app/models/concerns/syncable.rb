# Apply this mix-in to any model that needs to work with the sync API.
# Specify which properties the model will push through the sync layer.
#
#   syncs :name, :calories, :date                         # plain record
#   syncs :weight, :date, unique_by: :date                # at most one record per user per day
#   syncs :date, parent: :tag, unique_by: %i[tag_id date] # child of another synced model
#
# use 'unique_by' to identify the column(s) that identify sync constraints, such as
# limiting one entry per user per day. Use a lambda for custom matching.
#
# Every create, update, and destroy action appends a new SyncEvent inside the transaction.
# The sync event 'feed' is what devices use as a ledger to coordinate with the server. Writes
# that skip callbacks like update_all, delete_all, update_column will NOT create a sync event.
# see: `rake sync:reemit`.

module Syncable
  extend ActiveSupport::Concern

  # Only accept lowercase UUIDs because SQLite's indexes are case-sensitive
  UUID_FORMAT = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/

  included do
    before_validation :assign_uuid, on: :create
    validates :uuid, presence: true, format: { with: UUID_FORMAT, allow_blank: true }
    validate  :uuid_never_changes, on: :update
    after_save    :log_sync_event, if: :saved_changes?
    after_destroy :log_sync_event
  end

  class_methods do
    def syncs(*fields, parent: nil, unique_by: nil)
      @sync_config = { fields: fields.map(&:to_s), parent: parent, unique_by: unique_by }
    end

    def sync_config
      @sync_config or raise NotImplementedError, "#{name} includes Syncable but never calls `syncs`"
    end

    def sync_type
      name.underscore
    end

    def owned_by(user)
      where(user_id: user.id)
    end

    def find_sync_clash(scope, attrs)
      rule = sync_config[:unique_by]

      case rule
      when nil
        nil
      when Proc
        rule.call(scope, attrs)
      else
        conditions = Array.wrap(rule).to_h { |column| [ column, attrs[column.to_s] ] }
        scope.find_by(conditions)
      end
    end
  end

  def sync_type
    self.class.sync_type
  end

  def sync_owner_id
    user_id
  end

  private

  def assign_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def uuid_never_changes
    errors.add(:uuid, "can't be changed") if uuid_changed?
  end

  def log_sync_event
    SyncEvent.create!(user_id: sync_owner_id, record_type: sync_type, uuid: uuid)
  end
end
