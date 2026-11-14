namespace :sync do
  desc "re-announce every record for devices to redownload"
  task reemit: :environment do
    SyncRegistry.models.each do |model|
      model.find_each do |record|
        SyncEvent.create!(
          user_id: record.sync_owner_id,
          record_type: record.sync_type,
          uuid: record.uuid
        )
      end
    end
  end
end
