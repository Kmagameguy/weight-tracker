class CreateJournalEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :journal_entries do |t|
      t.date       :date, null: false
      t.text       :note
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :journal_entries, [ :user_id, :date ], unique: true
  end
end
