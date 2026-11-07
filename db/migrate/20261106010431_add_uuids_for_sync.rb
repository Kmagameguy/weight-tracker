class AddUuidsForSync < ActiveRecord::Migration[8.1]
  TABLES = %i[food_entries weight_entries blood_pressure_readings
              journal_entries tags day_tags].freeze
  def up
    TABLES.each do |table|
      add_column table, :uuid, :string
      select_values("SELECT id FROM #{table}").each do |id|
        execute "UPDATE #{table} SET uuid = #{connection.quote(SecureRandom.uuid)} WHERE id = #{id.to_i}"
      end
      change_column_null table, :uuid, false
      add_index table, :uuid, unique: true
    end
  end

  def down
    TABLES.each { |table| remove_column table, :uuid }
  end
end
