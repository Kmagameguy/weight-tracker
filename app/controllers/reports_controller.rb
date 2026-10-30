class ReportsController < ApplicationController
  def show
    start_date, end_date = requested_range

    @report = DoctorVisitReportPresenter.new(
      user: Current.user,
      start_date: start_date,
      end_date: end_date,
      include_calories: include_calories?,
      include_weights: include_weights?,
      include_blood_pressure_readings: include_blood_pressure_readings?,
      include_tags: include_tags?,
      include_journal: include_journal?
    )
  end

  private

  def requested_range
    today      = Date.current
    end_date   = parse_date(params[:end_date]) || today
    start_date = parse_date(params[:start_date]) || end_date - (DoctorVisitReportPresenter::DEFAULT_RANGE_DAYS - 1)

    start_date, end_date = end_date, start_date if start_date > end_date
    end_date   = [ end_date, today ].min
    start_date = [ start_date, end_date ].min

    earliest = end_date - (DoctorVisitReportPresenter::MAX_RANGE_DAYS - 1)
    if start_date < earliest
      start_date = earliest
      flash.now[:alert] =
        "Reports are limited to #{DoctorVisitReportPresenter::MAX_RANGE_DAYS} days." \
        "Showing the most recent #{DoctorVisitReportPresenter::MAX_RANGE_DAYS} days of your selection."
    end

    [ start_date, end_date ]
  end

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end

  def include_calories?
    return true if params[:include_calories].blank?

    params[:include_calories] == "1"
  end

  def include_weights?
    return true if params[:include_weights].blank?

    params[:include_weights] == "1"
  end

  def include_blood_pressure_readings?
    return true if params[:include_blood_pressure_readings].blank?

    params[:include_blood_pressure_readings] == "1"
  end

  def include_tags?
    return true if params[:include_tags].blank?

    params[:include_tags] == "1"
  end

  def include_journal?
    params[:include_journal] == "1"
  end
end
