class CalendarsController < ApplicationController
  before_action :validate_date

  def show; end

  private

  def user_today
    tz = Current.user&.timezone || Time.zone.name
    Time.now.in_time_zone(tz).to_date
  end

  def validate_date
    day = params[:day].presence || 1
    @date = Date.new(params[:year].to_i, params[:month].to_i, day.to_i)
    raise Date::Error if @date > user_today.beginning_of_month
  rescue Date::Error, ArgumentError
    @date = user_today
  end
end
