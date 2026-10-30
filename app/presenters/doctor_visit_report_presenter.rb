# frozen_string_literal: true

class DoctorVisitReportPresenter
  DEFAULT_RANGE_DAYS = 30
  MAX_RANGE_DAYS     = 366
  BLOOD_PRESSURE_CATEGORY_RANK = {
    BloodPressureReading::NORMAL_BLOOD_PRESSURE   => 0,
    BloodPressureReading::ELEVATED_BLOOD_PRESSURE => 1,
    BloodPressureReading::STAGE_ONE_HYPERTENSION  => 2,
    BloodPressureReading::STAGE_TWO_HYPERTENSION  => 3
  }.freeze

  attr_reader :user, :start_date, :end_date

  def initialize(user:,
    start_date:,
    end_date:,
    include_calories: true,
    include_weights: true,
    include_blood_pressure_readings: true,
    include_tags: true,
    include_journal: false)
    @user             = user
    @start_date       = start_date
    @end_date         = end_date
    @include_calories = include_calories
    @include_weights  = include_weights
    @include_blood_pressure_readings = include_blood_pressure_readings
    @include_tags     = include_tags
    @include_journal  = include_journal
  end

  def range
    start_date..end_date
  end

  def day_count
    (end_date - start_date).to_i + 1
  end

  def include_calories?
    @include_calories && user.calorie_tracking_enabled?
  end

  def include_weights?
    @include_weights && user.weight_tracking_enabled?
  end

  def include_blood_pressure_readings?
    @include_blood_pressure_readings && user.blood_pressure_tracking_enabled?
  end

  def include_tags?
    @include_tags && user.tagging_enabled?
  end

  def include_journal?
    @include_journal && user.journaling_enabled?
  end

  def blank?
    user.all_features_disabled? ||
      !(include_calories? ||
        include_weights? ||
        include_blood_pressure_readings? ||
        include_tags? ||
        include_journal?)
  end

  def days_logged
    dates = []
    dates.concat(daily_calories.keys) if user.calorie_tracking_enabled?
    dates.concat(weight_entries.map(&:date)) if user.weight_tracking_enabled?
    dates.concat(blood_pressure_readings.map(&:date)) if user.blood_pressure_tracking_enabled?
    dates.concat(user.journal_entries.where(date: range).pluck(:date)) if user.journaling_enabled?
    dates.concat(range_day_tags.map(&:date)) if user.tagging_enabled?

    dates.uniq.size
  end

  def avg_daily_calories
    return if daily_calories.blank?

    (daily_calories.values.sum.to_f / daily_calories.size).round
  end

  def days_over_goal
    daily_calories.count { |_, total| total > user.daily_calorie_goal }
  end

  def days_at_or_under_goal
    daily_calories.count { |_, total| total <= user.daily_calorie_goal }
  end

  def highest_calorie_day
    daily_calories.max_by { |_, total| total }
  end

  def weight_change
    return if weight_entries.size < 2

    (weight_entries.last.weight - weight_entries.first.weight).round(1)
  end

  def min_weight
    weight_entries.min_by(&:weight)&.weight
  end

  def max_weight
    weight_entries.max_by(&:weight)&.weight
  end

  def avg_blood_pressure
    return if blood_pressure_readings.blank?

    count = blood_pressure_readings.size
    BloodPressureReading.new(
      date: end_date,
      systolic: (blood_pressure_readings.sum(&:systolic).to_f / count).round,
      diastolic: (blood_pressure_readings.sum(&:diastolic).to_f / count).round
    )
  end

  def most_severe_blood_pressure_reading
    blood_pressure_readings.max_by do |reading|
      [
        BLOOD_PRESSURE_CATEGORY_RANK.fetch(reading.category),
        reading.systolic,
        reading.diastolic
      ]
    end
  end

  def least_severe_blood_pressure_reading
    blood_pressure_readings.min_by do |reading|
      [
        BLOOD_PRESSURE_CATEGORY_RANK.fetch(reading.category),
        reading.systolic,
        reading.diastolic
      ]
    end
  end

  def blood_pressure_category_summaries
    total  = blood_pressure_readings.size
    counts = blood_pressure_category_counts
    return {} if total.zero?

    BLOOD_PRESSURE_CATEGORY_RANK.keys.map do |category|
      count = counts.fetch(category, 0)

      {
        category: category,
        count: count,
        percentage: (count.to_f / total * 100).round
      }
    end
  end

  def blood_pressure_category_counts
    blood_pressure_readings.group_by(&:category).transform_values(&:count)
  end

  def tags_on(date)
    tags_by_date.fetch(date, [])
  end

  def tag_summaries
    @tag_summaries ||= begin
      summaries = range_day_tags.group_by(&:tag_id).map do |_, day_tags|
        { name: day_tags.first.tag.name, days: day_tags.size, dates: day_tags.map(&:date).sort }
      end

      summaries.sort_by { |summary| [ -summary[:days], summary[:name] ] }
    end
  end

  def daily_calories
    @daily_calories ||= user.food_entries.where(date: range).group(:date).sum(:calories)
  end

  def weight_entries
    @weight_entries ||= user.weight_entries.where(date: range).order(:date).to_a
  end

  def blood_pressure_readings
    @blood_pressure_readings ||= user.blood_pressure_readings.where(date: range).order(:date).to_a
  end

  def journal_entries
    @journal_entries ||= user.journal_entries
                             .where(date: range)
                             .where.not(note: [ nil, "" ])
                             .order(:date)
                             .to_a
  end

  private

  def range_day_tags
    @range_day_tags ||= user.day_tags.includes(:tag).where(date: range).order(:date).to_a
  end

  def tags_by_date
    @tags_by_date ||= range_day_tags.group_by(&:date).transform_values do |day_tags|
      day_tags.map { |day_tag| day_tag.tag.name }.sort
    end
  end
end
