class CalendarPresenter
  WEEK_DAY_HEADERS = %w[Mo Tu We Th Fr Sa Su].freeze

  attr_reader :date, :today

  def initialize(date:)
    @date  = date
    @today = Date.current
  end

  def days
    (first_day..last_day).to_a
  end

  def start_offset
    (first_day.wday - 1) % 7
  end

  def prev_month
    @prev_month ||= date - 1.month
  end

  def next_month
    @next_month ||= date + 1.month
  end

  def future_month?
    date.year > today.year ||
      (date.year == today.year && date.month > today.month)
  end

  def current_month?
    date.month == today.month && date.year == today.year
  end

  def day_status(day)
    if day > today
      :future
    elsif day == date
      :selected
    elsif day == today
      :today
    else
      :default
    end
  end

  def first_day
    @first_day ||= date.beginning_of_month
  end

  def last_day
    @last_day ||= date.end_of_month
  end
end
