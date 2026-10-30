class AddJournalAndTagFeatureToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :journaling_enabled, :boolean, null: false, default: true
    add_column :users, :tagging_enabled,    :boolean, null: false, default: true
  end
end
