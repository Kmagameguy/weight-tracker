class CreateDayTags < ActiveRecord::Migration[8.1]
  def change
    create_table :day_tags do |t|
      t.references :tag,  null: false, foreign_key: true
      t.date       :date, null: false

      t.timestamps
    end
    add_index :day_tags, [ :tag_id, :date ], unique: true
    add_index :day_tags, :date
  end
end
