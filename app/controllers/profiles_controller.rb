class ProfilesController < ApplicationController
  before_action :set_user, only: %i[show update]

  def show
    @days_over_budget =
      @user.food_entries
           .group(:date)
           .sum(:calories)
           .select { |date, total_calories| total_calories > @user.daily_calorie_goal }
           .count

    days = @user.food_entries.pluck(:date).uniq.count
    @calorie_deficit = (days * 2_000) - @user.food_entries.sum(:calories)
  end

  def update
    if @user.update(user_params)
      flash[:notice] = "Daily calorie goal updated successfully."
      redirect_to profile_path
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = Current.user
  end

  def user_params
    params.expect(user: [:daily_calorie_goal])
  end
end
