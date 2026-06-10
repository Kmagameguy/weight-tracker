require "test_helper"

class CalendarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  describe "#show" do
    it "renders successfully" do
      get calendar_path(year: 2026, month: 6, day: 9)
      assert_response :success
    end

    it "renders the calendar grid partial" do
      get calendar_path(year: 2026, month: 6, day: 9)
      assert_select "#calendar_grid"
    end

    it "clamps to today when a future month is requested" do
      future = Date.current + 2.months
      get calendar_path(year: future.year, month: future.month, day: 1)
      assert_select "span", text: Date.current.strftime("%B %Y")
    end

    it "allows nvaigating to past years" do
      get calendar_path(year: 2024, month: 10, day: 1)
      assert_response :success
      assert_select "span", text: "October 2024"
    end

    it "requires authentication" do
      sign_out
      get calendar_path(year: 2026, month: 6, day: 9)
      assert_redirected_to new_session_path
    end
  end
end
