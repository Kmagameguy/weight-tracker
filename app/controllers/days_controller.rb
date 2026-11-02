class DaysController < ApplicationController
  include DateValidatable

  skip_before_action :validate_date, only: :today

  def today
    redirect_to(day_path_for(user_today))
  end

  def show
    @day_presenter = ::DayPresenter.new(user: Current.user, date: @date)
  end

  private

  def validate_date
    @date = date_from_params
    redirect_to day_path_for(user_today), alert: "Invalid day!" unless @date
  end
end
