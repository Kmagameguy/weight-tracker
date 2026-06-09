class DayPresenter
  attr_reader :user, :date

  def initialize(user:, date:)
    @user = user
    @date = date
  end

  def prev_day
    date - 1.day
  end

  def next_day
    date + 1.day
  end

  def today?
    date == Date.current
  end

  def total_calories
    food_entries.sum(:calories)
  end

  def calories_remaining
    daily_calorie_goal - total_calories
  end

  def daily_calorie_goal
    user.daily_calorie_goal
  end

  def new_food_entry
    @new_food_entry ||= user.food_entries.build(date: date)
  end

  def new_weight_entry
    @new_weight_entry ||= user.weight_entries.build(date: date)
  end

  def last_weight_entry
    weight_entries.max_by(&:date)
  end

  def weight_entry
    weight_entries.find_by(date: date)
  end

  def food_entries
    @food_entries ||= user.food_entries.where(date: date).order(:created_at)
  end

  def weight_entries
    @weight_entries ||= user.weight_entries
  end
end
