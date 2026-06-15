# frozen_string_literal: true

class WeightChangesChartPresenter
  DEFAULT_Y_AXIS_BUFFER = 10

  def initialize(user:)
    @user = user
  end

  def weights_present?
    user && user.weight_entries.exists?
  end

  def title
    "Weight Changes Over Time (lbs)"
  end

  def data
    ordered_weight_entries.pluck(:date, :weight).to_h
  end

  def y_axis_min
    weight = ordered_weight_entries.minimum(:weight)
    weight ? weight - DEFAULT_Y_AXIS_BUFFER : nil
  end

  def y_axis_max
    weight = ordered_weight_entries.maximum(:weight)
    weight ? weight + DEFAULT_Y_AXIS_BUFFER : nil
  end

  private

  def ordered_weight_entries
    @ordered_weight_entries ||= user.weight_entries.order(:date)
  end

  attr_reader :user
end
