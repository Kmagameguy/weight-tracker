require "test_helper"

class WeightChangesChartPresenterTeset < ActiveSupport::TestCase
  setup { @user = users(:one) }

  describe "constants" do
    it "exposes the DEFAULT_Y_AXIS_BUFFER constant" do
      assert defined?(WeightChangesChartPresenter::DEFAULT_Y_AXIS_BUFFER)
      assert_equal 10, WeightChangesChartPresenter::DEFAULT_Y_AXIS_BUFFER
    end
  end

  describe "#weights_present?" do
    it "is true when a user has weight entries" do
      presenter = WeightChangesChartPresenter.new(user: @user)
      assert_predicate presenter, :weights_present?
    end

    it "is false when a user does not have weight entries" do
      @user.weight_entries.destroy_all
      presenter = WeightChangesChartPresenter.new(user: @user)

      assert_not_predicate presenter, :weights_present?
    end

    it "is false if the user is nil" do
      presenter = WeightChangesChartPresenter.new(user: nil)
      assert_not_predicate presenter, :weights_present?
    end
  end

  describe "#data" do
    it "creates a structured hash from the weight entries" do
      @user.weight_entries.destroy_all
      today = Date.current
      yesterday = today - 1.day
      last_week = today - 1.week
      [
        { date: yesterday, weight: 245.2 },
        { date: today, weight: 223.5 },
        { date: last_week, weight: 225.2 }
      ].each do |weight_entry|
        @user.weight_entries.create!(date: weight_entry[:date], weight: weight_entry[:weight])
      end

      expected_data_hash = {
        last_week => BigDecimal("225.2"),
        yesterday => BigDecimal("245.2"),
        today => BigDecimal("223.5")
      }

      presenter = WeightChangesChartPresenter.new(user: @user)
      assert_equal expected_data_hash, presenter.data
    end

    it "returns an empty hash when there are no weight entries" do
      @user.weight_entries.destroy_all
      assert_equal({}, WeightChangesChartPresenter.new(user: @user).data)
    end
  end

  describe "#y_axis_min" do
    it "subtracts the buffer from the minimum-recorded weight value" do
      assert_equal 235.5, WeightChangesChartPresenter.new(user: @user).y_axis_min
    end

    it "returns nil if there are no weight entries" do
      @user.weight_entries.destroy_all
      assert_nil WeightChangesChartPresenter.new(user: @user).y_axis_min
    end
  end

  describe "#y_axis_man" do
    it "adds the buffer to the maximum-recorded weight value" do
      assert_equal 255.5, WeightChangesChartPresenter.new(user: @user).y_axis_max
    end

    it "returns nil if there are no weight entries" do
      @user.weight_entries.destroy_all
      assert_nil WeightChangesChartPresenter.new(user: @user).y_axis_max
    end
  end
end
