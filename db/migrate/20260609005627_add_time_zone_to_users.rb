class AddTimeZoneToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :timezone, :string, null: false, default: "Etc/UTC"
  end
end
