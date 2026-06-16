class CreateBloodPressureReadings < ActiveRecord::Migration[8.1]
  def change
    create_table :blood_pressure_readings do |t|
      t.integer    :systolic,  null: false
      t.integer    :diastolic, null: false
      t.date       :date,      null: false
      t.references :user,      null: false, foreign_key: true

      t.timestamps
    end
    add_index :blood_pressure_readings, [ :user_id, :date ], unique: true
  end
end
