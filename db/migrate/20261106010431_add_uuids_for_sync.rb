class AddUuidsForSync < ActiveRecord::Migration[8.1]
  # Tables that already exist and must start carrying a device-visible identity.
  # A table created from now on declares its own uuid in its create_table instead,
  # so this list never grows.
  TABLES = %i[
    food_entries weight_entries blood_pressure_readings
    journal_entries tags day_tags
  ].freeze

  def up
    TABLES.each do |table|
      add_column table, :uuid, :string
      backfill_uuids(table)
      change_column_null table, :uuid, false
      add_index table, :uuid, unique: true
    end
  end

  def down
    TABLES.each do |table|
      remove_index table, column: :uuid, if_exists: true
      remove_column table, :uuid if column_exists?(table, :uuid)
    end
  end

  private

  # One UPDATE per row, using the same generator the app uses, so backfilled ids always
  # match the format the sync API accepts. `connection` is called directly so the
  # migration doesn't print a line per row.
  def backfill_uuids(table)
    quoted = connection.quote_table_name(table)
    ids    = connection.select_values("SELECT id FROM #{quoted}")

    ids.each do |id|
      uuid = connection.quote(SecureRandom.uuid)
      connection.execute("UPDATE #{quoted} SET uuid = #{uuid} WHERE id = #{id.to_i}")
    end
  end
end
