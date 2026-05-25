class CreateFoodEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :food_entries do |t|
      t.string     :name,     null: false
      t.integer    :calories, null: false, default: 0
      t.date       :date,     null: false
      t.references :user,     null: false, foreign_key: true

      t.timestamps
    end
    add_index :food_entries, :date
  end
end
