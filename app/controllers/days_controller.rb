class DaysController < ApplicationController
  before_action :validate_date

  def show
    @day_presenter = ::DayPresenter.new(user: Current.user, date: @date)
  end

  private

  def validate_date
    @date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
    raise Date::Error if @date > Date.today
  rescue Date::Error
    redirect_to day_path_for(Date.today), alert: "Invalid day!"
  end
end
