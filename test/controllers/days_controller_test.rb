require "test_helper"

class DaysControllerTest < ActionDispatch::IntegrationTest
  include RoutingHelper

  setup do
    @user = users(:one)
    @date = Date.parse("2026-06-05 05:00:00")
    sign_in_as(@user)
  end

  describe "#show" do
    context "page routing" do
      it "redirects unauthenticated users" do
        sign_out
        get day_path_for(Date.today)
        assert_redirected_to new_session_path
      end

      it "shows today's date when navigating to today" do
        today = @date
        get day_path_for(today)
        assert_response :success
        assert_select "h1", text: today.strftime("%B %-d")
      end

      it "shows a past date successfully" do
        past = @date - 1.day
        get day_path_for(past)
        assert_response :success
        assert_select "h1", text: past.strftime("%B %-d")
      end

      it "redirects to today when a future date is requested" do
        today = Date.today
        future_day = today + 1.week
        get day_path_for(future_day)
        assert_redirected_to day_path_for(today)
        follow_redirect!
        assert_select ".bg-red-50", text: /Invalid day!/
      end

      it "redirects to today when a non-real date is requested" do
        get "/days/2026/06/44"
        assert_redirected_to day_path_for(Date.today)
        follow_redirect!
        assert_select ".bg-red-50", text: /Invalid day!/
      end
    end

    context "page structure" do
      it "renders the sticky header with date navigation" do
        today = Date.today
        get day_path_for(today)
        assert_select "header" do
          assert_select "a#prev-day-nav", text: /#{(today - 1.day).strftime("%b %-d")}/
          assert_select "a#next-day-nav", count: 0
        end
      end

      it "renders the next day link when viewing a past date" do
        prev_date = @date - 1.week
        get day_path_for(prev_date)
        assert_select "a#next-day-nav", text: /#{(prev_date + 1.day).strftime("%b %-d")}/
      end

      it "renders the food entry form" do
        get day_path_for(@date)
        assert_select "#food_entry_form"
        assert_select "#food_entry_form form"
      end

      it "renders 'nothing logged yet' when no food entries exist" do
        @user.food_entries.destroy_all
        get day_path_for(@date)
        assert_select "p", text: /Nothing logged yet today/
      end

      it "renders food entries when they exist" do
        food_entry = food_entries(:burrito)
        get day_path_for(food_entry.consumed_on)
        assert_select "#food_entries"
        assert_select "#food_entry_#{food_entry.id}"
      end

      it "renders the weight entry turbo frame" do
        get day_path_for(@date)
        assert_select "turbo-frame#weight_entry"
      end

      it "renders weight entry form when no weigh-in exists for the day" do
        WeightEntry.all.destroy_all
        get day_path_for(Date.today)
        assert_select "turbo-frame#weight_entry form"
      end

      it "renders existing weight entry when one exists" do
        WeightEntry.all.destroy_all
        today = Date.today
        weight_entry = @user.weight_entries.create!(date: today, weight: 245.2)
        get day_path_for(today)
        assert_select "#weight_entry_weight", count: 0
        assert_select "turbo-frame#weight_entry", text: /#{weight_entry.weight}/
      end
    end

    context "turbo frame requests" do
      it "responds to turbo frame requests for weight_entry frame" do
        get day_path_for(@date), headers: { "Turbo-Frame" => "weight_entry" }
        assert_response :success
        assert_select "turbo-frame#weight_entry"
      end
    end
  end
end
