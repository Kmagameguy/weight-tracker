class DaysController < ApplicationController
  def show
    @day_presenter = ::DayPresenter.new(user: Current.user, date: parse_date)
  end

  private

  def parse_date
    requested_date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
    raise Date::Error if requested_date > Date.today

    requested_date
  rescue Date::Error
    redirect_to(day_path_for(Date.today), alert: "Invalid day!") and return
  end
end
