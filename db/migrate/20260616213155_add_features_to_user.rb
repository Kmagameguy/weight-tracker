class AddFeaturesToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :calorie_tracking_enabled,        :boolean, null: false, default: true
    add_column :users, :weight_tracking_enabled,         :boolean, null: false, default: true
    add_column :users, :blood_pressure_tracking_enabled, :boolean, null: false, default: true
  end
end
