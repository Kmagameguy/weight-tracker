class DaysController < ApplicationController
  def show
    @date              = parse_date
    @food_entries      = Current.user.food_entries.where(date: @date).order(:created_at)
    @total_calories    = @food_entries.sum(:calories)
    @daily_calorie_goal = Current.user.daily_calorie_goal
    @calories_remaining = @daily_calorie_goal - @total_calories
    @last_weight_entry = Current.user.weight_entries.max_by(&:date)
    @weight_entry      = Current.user.weight_entries.find_by(date: @date)
    @new_food_entry    = Current.user.food_entries.build(date: @date)
    @new_weight_entry  = Current.user.weight_entries.build(date: @date)
  end

  private

  def parse_date
    Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
  rescue Date::Error
    redirect_to day_path_for(Date.today) and return
  end
end
