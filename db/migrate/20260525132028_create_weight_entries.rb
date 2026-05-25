class CreateWeightEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :weight_entries do |t|
      t.decimal    :weight, null: false, precision: 4, scale: 1
      t.date       :date,   null: false
      t.references :user,   null: false, foreign_key: true

      t.timestamps
    end
    add_index :weight_entries, [:user_id, :date], unique: true
  end
end
