require "test_helper"

class FoodEntriesControllerTest < ActionDispatch::IntegrationTest
  include RoutingHelper

  setup do
    @user = users(:one)
    sign_in_as(@user)
    @food_entry = @user.food_entries.first
  end

  describe "authentication" do
    before { sign_out }

    it "redirects unauthenticated users away from the create action" do
      assert_no_difference("FoodEntry.count") do
        post food_entries_path, params: { name: "Burrito", calories: 125, date: Date.current }
      end
      assert_redirected_to new_session_path
    end

    it "redirects unauthenticated users away from the edit action" do
      get edit_food_entry_path @food_entry
      assert_redirected_to new_session_path
    end

    it "redirects unauthorized users away from the destroy action" do
      assert_no_difference("FoodEntry.count") do
        delete food_entry_path @food_entry
      end
      assert_redirected_to new_session_path
    end
  end

  describe "#create" do
    context "with valid params" do
      before do
        post food_entries_path,
          params:  { food_entry: { name: "Banana", calories: 105, date: Date.current } },
          as: :turbo_stream
      end

      it "creates a new food entry" do
        assert_difference("FoodEntry.count", 1) do
          post food_entries_path, params: {
            food_entry: { name: "Soup", calories: 300, date: Date.current }
          }
        end
      end

      it "appends the new entry to #food_entries" do
        assert_response :success
        assert_equal "text/vnd.turbo-stream.html", response.media_type
        assert_select "turbo-stream[action=append][target=food_entries]"
      end

      it "replaces the calories summary" do
        assert_select "turbo-stream[action=replace][target=calories_summary]"
      end

      it "resets the food entry form" do
        assert_select "turbo-stream[action=update][target=food_entry_form]"
      end

      it "redirects to the day page for html requests" do
        date = Date.current - 1.day
        post food_entries_path, params: {
          food_entry: { name: "Soup", calories: 300, date: date }
        }

        assert_redirected_to day_path_for(date)
      end
    end

    context "with invalid params" do
      it "does not create a food entry" do
        assert_no_difference("FoodEntry.count") do
          post food_entries_path, params: {
            food_entry: { name: "", calories: nil, date: Date.current }
          }
        end
      end

      it "redirects back to the day page with an alert" do
        post food_entries_path, params: {
          food_entry: { name: "", calories: nil, date: Date.current }
        }

        assert_redirected_to day_path_for(Date.current)
        follow_redirect!
        assert_select ".bg-red-50", text: /Name can\'t be blank/
      end
    end
  end

  describe "#edit" do
    it "renders the form successfully" do
      get edit_food_entry_path @food_entry
      assert_response :success
    end

    it "cannot edit another user's food entry" do
      other_entry = users(:two).food_entries.first
      get edit_food_entry_path other_entry
      assert_response :not_found
    end
  end

  describe "#update" do
    context "with valid params" do
      before do
        patch food_entry_path(@food_entry),
          params: { food_entry: { name: "Updated Soup", calories: 800, date: @food_entry.date } },
          as: :turbo_stream
      end

      it "updates the food entry" do
        original_calories = @food_entry.calories
        patch food_entry_path @food_entry, params: {
          food_entry: { name: "New Food Thing", calories: original_calories + 100, date: @food_entry.date }
        }

        @food_entry.reload
        assert_equal "New Food Thing", @food_entry.name
        assert_not_equal original_calories, @food_entry.calories
      end

      it "replaces the food entry in the list" do
        assert_equal "text/vnd.turbo-stream.html", response.media_type
        assert_select "turbo-stream[action=replace][target=food_entry_#{@food_entry.id}]"
      end

      it "replaces the calories summary" do
        assert_select "turbo-stream[action=replace][target=calories_summary]"
      end

      it "redirects to the day page for html requests" do
        patch food_entry_path(@food_entry), params: {
          food_entry: { name: "New Food Thing", calories: 800, date: @food_entry.date }
        }

        assert_redirected_to day_path_for(@food_entry.reload.date)
      end
    end

    context "with invalid params" do
      it "does not update the food entry" do
        original_name = @food_entry.name
        original_calories = @food_entry.calories
        patch food_entry_path(@food_entry), params: {
          food_entry: { name: "", calories: nil, date: @food_entry.date }
        }

        @food_entry.reload

        assert_response :unprocessable_entity
        assert_equal original_name, @food_entry.name
        assert_equal original_calories, @food_entry.calories
      end

      it "won't update another user's food entry" do
        other_entry = users(:two).food_entries.first
        patch food_entry_path(other_entry), params: {
          food_entry: { name: "Hacked", calories: 100, date: @food_entry.date }
        }

        assert_response :not_found
      end
    end
  end

  describe "#destroy" do
    context "with valid params" do
      it "deletes the food entry" do
        assert_difference("FoodEntry.count", -1) do
          delete food_entry_path @food_entry
        end
      end

      it "removes the food entry from the list" do
        delete food_entry_path(@food_entry), as: :turbo_stream

        assert_response :success
        assert_equal "text/vnd.turbo-stream.html", response.media_type
        assert_select "turbo-stream[action=remove][target=food_entry_#{@food_entry.id}]"
      end

      it "replaces the calories summary" do
        delete food_entry_path(@food_entry), as: :turbo_stream

        assert_select "turbo-stream[action=replace][target=calories_summary]"
      end

      it "redirects to the day page for html requests" do
        date = @food_entry.date
        delete food_entry_path(@food_entry)

        assert_redirected_to day_path_for(date)
      end
    end

    context "with invalid params" do
      it "won't destroy another user's food entry" do
        other_entry = users(:two).food_entries.first
        delete food_entry_path(other_entry)

        assert_response :not_found
      end
    end
  end
end
