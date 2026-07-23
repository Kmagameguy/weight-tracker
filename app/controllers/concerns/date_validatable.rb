module DateValidatable
  extend ActiveSupport::Concern

  included do
    before_action :validate_date
  end

  private

  def user_today
    tz = Current.user&.timezone || Time.zone.name
    Time.current.in_time_zone(tz).to_date
  end

  def date_from_params(default_day: nil)
    day = params[:day] || default_day
    date = Date.new(params[:year].to_i, params[:month].to_i, day.to_i)
    date > user_today ? nil : date
  rescue Date::Error, ArgumentError
    nil
  end
end
