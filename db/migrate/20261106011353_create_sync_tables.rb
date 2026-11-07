class CreateSyncTables < ActiveRecord::Migration[8.1]
  SYNCABLE_TABLES = {
    "tag"                    => "tags",
    "food_entry"             => "food_entries",
    "weight_entry"           => "weight_entries",
    "blood_pressure_reading" => "blood_pressure_readings",
    "journal_entry"          => "journal_entries"
  }.freeze

  def up
    create_table :sync_events do |t|
      t.references :user,    null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :record_type, null: false
      t.string :uuid,        null: false
    end
    add_index :sync_events, %i[user_id id]

    create_table :api_tokens do |t|
      t.references :user,         null: false, foreign_key: true
      t.string     :token_digest, null: false
      t.string     :name
      t.datetime   :last_used_at

      t.timestamps
    end
    add_index :api_tokens, :token_digest, unique: true

    backfill_sync_events
  end

  def down
    drop_table :api_tokens,  if_exists: true
    drop_table :sync_events, if_exists: true
  end

  private

  def backfill_sync_events
    SYNCABLE_TABLES.each do |type, table|
      execute <<~SQL
        INSERT INTO sync_events (user_id, record_type, uuid)
        SELECT user_id, #{connection.quote(type)}, uuid FROM #{table} ORDER BY id
      SQL
    end

    execute <<~SQL
      INSERT INTO sync_events (user_id, record_type, uuid)
      SELECT tags.user_id, 'day_tag', day_tags.uuid
      FROM day_tags INNER JOIN tags ON tags.id = day_tags.tag_id
      ORDER BY day_tags.id
    SQL

    tables   = SYNCABLE_TABLES.values + [ "day_tags" ]
    expected = tables.sum { |table| connection.select_value("SELECT COUNT(*) FROM #{table}").to_i }
    actual   = connection.select_value("SELECT COUNT(*) FROM sync_events").to_i

    if actual != expected
      raise "sync_events backfill wrote #{actual} events for #{expected} records"
    end
  end
end
