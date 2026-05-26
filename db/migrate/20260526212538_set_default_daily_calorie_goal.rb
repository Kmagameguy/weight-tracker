class SetDefaultDailyCalorieGoal < ActiveRecord::Migration[8.1]
  def up
    User.update_all(daily_calorie_goal: 2000)
  end

  def down
    User.update_all(daily_calorie_goal: nil)
  end
end
