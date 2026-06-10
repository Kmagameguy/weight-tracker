require "test_helper"

class CalendarPresenterTest < ActiveSupport::TestCase
  setup do
    @today = Date.new(2026, 6, 9)
    Date.stubs(:current).returns(@today)
  end

  describe "#initialize" do
    it "sets date and today" do
      presenter = CalendarPresenter.new(date: @today)
      assert_equal @today, presenter.date
      assert_equal @today, presenter.today
    end
  end

  describe "#days" do
    it "returns all days in the month" do
      presenter = CalendarPresenter.new(date: Date.new(2026, 6, 1))
      assert_equal 30, presenter.days.count
      assert_equal Date.new(2026, 6, 1), presenter.days.first
      assert_equal Date.new(2026, 6, 30), presenter.days.last
    end
  end

  describe "#start_offset" do
    it "returns 0 for a month starting on Monday" do
      presenter = CalendarPresenter.new(date: Date.new(2026, 6, 1))
      assert_equal 0, presenter.start_offset
    end

    it "returns 1 for a month starting on Tuesday" do
      presenter = CalendarPresenter.new(date: Date.new(2026, 9, 1))
      assert_equal 1, presenter.start_offset
    end

    it "returns 6 for a month starting on Sunday" do
      presenter = CalendarPresenter.new(date: Date.new(2026, 11, 1))
      assert_equal 6, presenter.start_offset
    end
  end

  describe "#prev_month" do
    it "returns the previous month" do
      presenter = CalendarPresenter.new(date: Date.new(2026, 6, 15))
      assert_equal Date.new(2026, 5, 15), presenter.prev_month
    end

    it "crosses year boundaries correctly" do
      presenter = CalendarPresenter.new(date: Date.new(2026, 1, 15))
      assert_equal Date.new(2025, 12, 15), presenter.prev_month
    end
  end

  describe "#next_month" do
    it "returns the next month" do
      presenter = CalendarPresenter.new(date: Date.new(2026, 6, 15))
      assert_equal Date.new(2026, 7, 15), presenter.next_month
    end

    it "crosses year boundaries correctly" do
      presenter = CalendarPresenter.new(date: Date.new(2026, 12, 15))
      assert_equal Date.new(2027, 1, 15), presenter.next_month
    end
  end

  describe "#future_month?" do
    it "returns false for the current month" do
      presenter = CalendarPresenter.new(date: @today)
      assert_not_predicate presenter, :future_month?
    end

    it "returns false for a past month in the same year" do
      presenter = CalendarPresenter.new(date: Date.new(2026, 5, 1))
      assert_not_predicate presenter, :future_month?
    end

    it "returns false for a past year" do
      presenter = CalendarPresenter.new(date: Date.new(2025, 6, 1))
      assert_not_predicate presenter, :future_month?
    end

    it "returns true for a future month in the same year" do
      presenter = CalendarPresenter.new(date: Date.new(2026, 7, 1))
      assert_predicate presenter, :future_month?
    end

    it "returns true for a future year" do
      presenter = CalendarPresenter.new(date: Date.new(2027, 1, 1))
      assert_predicate presenter, :future_month?
    end
  end

  describe "#current_month?" do
    it "returns true when the date is in the current month and year" do
      presenter = CalendarPresenter.new(date: Date.new(2026, 6, 1))
      assert_predicate presenter, :current_month?
    end

    it "returns false when the month differs" do
      presenter = CalendarPresenter.new(date: Date.new(2026, 5, 9))
      assert_not_predicate presenter, :current_month?
    end

    it "returns false when the year differs" do
      presenter = CalendarPresenter.new(date: Date.new(2025, 6, 9))
      assert_not_predicate presenter, :current_month?
    end
  end

  describe "#first_day" do
    it "returns the first day of the month" do
      presenter = CalendarPresenter.new(date: Date.new(2026, 6, 15))
      assert_equal Date.new(2026, 6, 1), presenter.first_day
    end
  end

  describe "#last_day" do
    it "returns the last day of the month" do
      presenter = CalendarPresenter.new(date: Date.new(2026, 6, 15))
      assert_equal Date.new(2026, 6, 30), presenter.last_day
    end

    it "handles months with 31 days" do
      presenter = CalendarPresenter.new(date: Date.new(2026, 7, 1))
      assert_equal Date.new(2026, 7, 31), presenter.last_day
    end

    it "handles February in a leap year" do
      presenter = CalendarPresenter.new(date: Date.new(2024, 2, 1))
      assert_equal Date.new(2024, 2, 29), presenter.last_day
    end

    it "handles February in a non-leap year" do
      presenter = CalendarPresenter.new(date: Date.new(2025, 2, 1))
      assert_equal Date.new(2025, 2, 28), presenter.last_day
    end
  end

  describe "#day_status" do
    it "returns :future for a day after today" do
      presenter = CalendarPresenter.new(date: @today)
      assert_equal :future, presenter.day_status(@today + 1.day)
    end

    it "returns :selected for the presenter's date" do
      presenter = CalendarPresenter.new(date: @today)
      assert_equal :selected, presenter.day_status(@today)
    end

    it "returns :today when the day is today but not the selected date" do
      presenter = CalendarPresenter.new(date: Date.new(2026, 6, 1))
      assert_equal :today, presenter.day_status(@today)
    end

    it "returns :default for a past day that is not today or selected" do
      presenter = CalendarPresenter.new(date: @today)
      assert_equal :default, presenter.day_status(@today - 1.day)
    end

    it "prioritises :selected over :today when date equals today" do
      presenter = CalendarPresenter.new(date: @today)
      assert_equal :selected, presenter.day_status(@today)
    end
  end

  describe "WEEK_DAY_HEADERS" do
    it "contains the correct abbreviated day names starting from Monday" do
      assert_equal %w[Mo Tu We Th Fr Sa Su], CalendarPresenter::WEEK_DAY_HEADERS
    end

    it "is frozen" do
      assert_predicate CalendarPresenter::WEEK_DAY_HEADERS, :frozen?
    end
  end
end
