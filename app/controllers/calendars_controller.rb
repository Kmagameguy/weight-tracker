class CalendarsController < ApplicationController
  include DateValidatable

  def show
    @calendar = CalendarPresenter.new(date: @date)
  end

  private

  def validate_date
    @date = date_from_params(default_day: 1) || user_today
  end
end
