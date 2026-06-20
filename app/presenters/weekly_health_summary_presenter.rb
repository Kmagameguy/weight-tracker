class WeeklyHealthSummaryPresenter
  using Refinements::IntegerRefinements

  attr_reader :user, :week_start, :week_end

  def initialize(user, week_start: Date.current.beginning_of_week)
    @user       = user
    @week_start = week_start
    @week_end   = week_start + 6.days
  end

  def previous_week
    @previous_week ||= self.class.new(user, week_start: week_start - 7.days)
  end

  def avg_daily_calories
    return unless user.calorie_tracking_enabled?

    totals = food_entries
      .group(:date)
      .sum(:calories)
      .values
    return if totals.blank?

    (totals.sum.to_f / totals.size).round
  end

  def weight_change
    return unless user.weight_tracking_enabled?

    first = weight_entries.order(:date).first&.weight
    last  = weight_entries.order(:date).last&.weight
    return unless first && last

    (last - first).round(1)
  end

  def avg_blood_pressure
    return unless user.blood_pressure_tracking_enabled?

    readings = bp_readings.pluck(:systolic, :diastolic)
    return if readings.blank?

    avg_sys = (readings.sum { |s, _| s }.to_f / readings.size).round
    avg_dia = (readings.sum { |_, d| d }.to_f / readings.size).round

    BloodPressureReading.new(date: Date.current, systolic: avg_sys, diastolic: avg_dia)
  end

  def calorie_diff
    return unless avg_daily_calories && previous_week.avg_daily_calories

    avg_daily_calories - previous_week.avg_daily_calories
  end

  def days_logged
    logged_days = []
    (logged_days += food_entries.pluck(:date))   if user.calorie_tracking_enabled?
    (logged_days += weight_entries.pluck(:date)) if user.weight_tracking_enabled?
    (logged_days += bp_readings.pluck(:date))    if user.blood_pressure_tracking_enabled?

    logged_days.uniq.count
  end

  def weekly_tips
    [
      perfectly_logged_week_tip,
      bp_elevation_tip,
      calorie_variance_tip,
      logging_streak_improved_tip
    ].compact
  end

  def fallback_tip
    "You logged #{days_logged.to_sequence} in 7 days. Consistent logging gives you more accurate insights."
  end

  private

  def perfectly_logged_week_tip
    return unless days_logged == 7

    "Perfect week! All 7 days logged. Consistent data entry makes trends much more reliable."
  end

  def bp_elevation_tip
    return unless (bp = avg_blood_pressure)
    return if bp.normal?

    "Your average blood pressure this week (#{bp.combined_value}) is in the #{bp.category} range. Worth discussing with your doctor if this persists."
  end

  def calorie_variance_tip
    return unless user.calorie_tracking_enabled?

    totals = food_entries.group(:date).sum(:calories).values
    return if totals.size < 4
    mean = totals.sum.to_f / totals.size
    variance = totals.sum { |v| (v - mean) ** 2 } / totals.size
    stddev = Math.sqrt(variance).round
    return unless stddev > 400

    "Your daily calories varied quite a bit this week (±#{stddev} cal). More consistency can help with weight trends."
  end

  def logging_streak_improved_tip
    this_week = days_logged
    last_week = previous_week.days_logged
    return unless this_week > last_week

    "You logged more days than last week (#{this_week} this week vs #{last_week} last week). Keep it up!"
  end

  def food_entries
    return @food_entries if defined?(@food_entries)

    @food_entries = user.food_entries.where(date: week_start..week_end)
  end

  def weight_entries
    return @weight_entries if defined?(@weight_entries)

    @weight_entries = user.weight_entries.where(date: week_start..week_end)
  end

  def bp_readings
    return @bp_readings if defined?(@bp_readings)

    @bp_readings = user.blood_pressure_readings.where(date: week_start..week_end)
  end
end
