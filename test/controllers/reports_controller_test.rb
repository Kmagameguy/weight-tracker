require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  include RoutingHelper

  setup do
    @user = users(:one)
    sign_in_as(@user)
    @params = { start_date: "2026-05-20", end_date: "2026-06-10" }
  end

  describe "#authentication" do
    before { sign_out }

    it "redirects unauthenticated users" do
      get report_path(@params)

      assert_redirected_to new_session_path
    end
  end

  describe "#show" do
    it "renders the report for the requested range" do
      get report_path(@params)

      assert_response :success
      assert_select "h1", text: "Health summary"
      assert_match(/May 20, 2026\s+&ndash;\s+Jun 10, 2026/, response.body)
    end

    it "defaults to the last 30 days with no params" do
      get report_path

      assert_response :success
      assert_match(/\(30 days\)/, response.body)
    end

    it "falls back to defaults for unparseable dates" do
      get report_path(start_date: "not-a-real-date", end_date: "bad-data")

      assert_response :success
    end

    it "swaps a reversed range" do
      get report_path(start_date: "2026-06-10", end_date: "2026-05-20")

      assert_match(/May 20, 2026\s+&ndash;\s+Jun 10, 2026/, response.body)
    end

    it "clamps a future end date to today" do
      get report_path(start_date: "2026-01-01", end_date: (Date.current + 1.week).to_s)

      assert_not_includes response.body, (Date.current + 1.week).strftime("%b %-d, %Y")
    end

    it "limits the range and shows an alert" do
      get report_path(start_date: "2020-01-01", end_date: "2026-06-10")

      assert_response :success
      assert_select ".bg-red-50", text: /limited to #{DoctorVisitReportPresenter::MAX_RANGE_DAYS} days/
    end

    it "selects calories, weights, blood pressure readings, and tags by default" do
      get report_path(@params)

      %w[ #report_calories #report_weight #report_blood_pressure #report_tags ].each do |section|
        assert_select section, count: 1
      end
    end

    it "leaves out journal notes by default" do
      get report_path(@params)

      assert_select "#report_journal", count: 0
    end

    it "shows sections for the selected topics" do
      users(:one).blood_pressure_readings.first.update!(date: @params[:start_date])
      get report_path(@params.merge(include_journal: "1"))

      assert_select "#report_calories", text: /1,000 cal/
      assert_select "#report_weight", text: /245\.5/
      assert_select "#report_blood_pressure", text: /Blood pressure Average 130\/80 mm Hg Highest category Stage 1 Hypertension/
      assert_select "#report_tags", text: /Headache/
      assert_select "#report_journal", text: /Had a pretty great day\./
    end

    it "hides sections for the unselected topics" do
      @user.update!(weight_tracking_enabled: false)
      get report_path(@params.merge(include_tags: "0"))

      assert_select "#report_calories", count: 1
      assert_select "#report_weight", count: 0
      assert_select "#report_tags", count: 0
    end
  end
end
