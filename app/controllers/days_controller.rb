class DaysController < ApplicationController
  include DateValidatable

  def show
    @day_presenter = ::DayPresenter.new(user: Current.user, date: @date)
  end

  private

  def validate_date
    @date = date_from_params
    redirect_to day_path_for(user_today), alert: "Invalid day!" unless @date
  end
end
