class DaysController < ApplicationController
  before_action :validate_date

  def show
    @day_presenter = ::DayPresenter.new(user: Current.user, date: @date)
  end

  private

  def user_today
    tz = Current.user&.timezone || Time.zone.name
    Time.now.in_time_zone(tz).to_date
  end

  def validate_date
    @date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
    raise Date::Error if @date > user_today
  rescue Date::Error
    redirect_to day_path_for(user_today), alert: "Invalid day!"
  end
end
