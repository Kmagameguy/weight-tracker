require "test_helper"

class WeightEntriesControllerTest < ActionDispatch::IntegrationTest
  include RoutingHelper

  setup do
    @user = users(:one)
    sign_in_as(@user)
    @weight_entry = @user.weight_entries.first
  end

  describe "authentication" do
    before { sign_out }

    it "redirects unauthenticated users away from create action" do
      assert_no_difference("WeightEntry.count") do
        post weight_entries_path, params: { weight: 182.4, date: Date.today }
      end
      assert_redirected_to new_session_path
    end

    it "redirects unauthenticated users away from the edit action" do
      get edit_weight_entry_path @weight_entry
      assert_redirected_to new_session_path
    end

    it "redirects unauthorized users away from the destroy action" do
      assert_no_difference("WeightEntry.count") do
        delete weight_entry_path @weight_entry
      end
      assert_redirected_to new_session_path
    end
  end

  describe "#create" do
    context "with valid params" do
      it "creates a new weight entry" do
        @user.weight_entries.destroy_all
        date = Date.today
        assert_difference("WeightEntry.count", 1) do
          post weight_entries_path, params: { weight_entry: { weight: 184.2, date: date } }
        end
        assert_not_empty @user.reload.weight_entries
      end

      it "redirects to the day page after creation" do
        @user.weight_entries.destroy_all
        date = Date.today
        post weight_entries_path, params: { weight_entry: { weight: 185.1, date: date } }
        new_weight_entry = WeightEntry.order(:created_at).last
        assert_redirected_to day_path_for(new_weight_entry)
      end

      it "scopes the weight entry to the logged-in user" do
        @user.weight_entries.destroy_all
        date = Date.today
        post weight_entries_path, params: { weight_entry: { weight: 111.5, date: date } }
        new_weight_entry = WeightEntry.order(:created_at).last
        assert_equal @user.id, new_weight_entry.user_id
      end
    end

    context "with invalid params" do
      it "does not create a weight entry" do
        assert_no_difference("WeightEntry.count") do
          post weight_entries_path, params: { weight_entry: { weight: nil, date: Date.today } }
        end
      end

      it "redirects back to the day page with an alert" do
        post weight_entries_path, params: { weight_entry: { weight: nil, date: Date.today } }
        assert_redirected_to day_path_for(Date.today)
        follow_redirect!
        assert_select ".bg-red-50", text: /Weight is not a number/
      end
    end
  end

  describe "#edit" do
    it "renders the form inside the turbo frame successfully" do
      get edit_weight_entry_path @weight_entry
      assert_response :success
      assert_select "turbo-frame#weight_entry"
    end

    it "won't edit another user's weight entry" do
      other_entry = users(:two).weight_entries.first
      get edit_weight_entry_path other_entry
      assert_response :not_found
    end
  end

  describe "#update" do
    context "with valid params" do
      it "updates the weight entry" do
        patch weight_entry_path @weight_entry, params: {
          weight_entry: { weight: 190.0, date: @weight_entry.date }
        }
        assert_equal 190.0, @weight_entry.reload.weight
      end

      it "redirects to the day page after a successful update" do
        patch weight_entry_path @weight_entry, params: {
          weight_entry: { weight: 190.0, date: @weight_entry.date }
        }
        assert_redirected_to day_path_for(@weight_entry.reload)
      end
    end

    context "with invalid params" do
      it "does not update the weight entry" do
        original_weight = @weight_entry.weight
        patch weight_entry_path @weight_entry, params: {
          weight_entry: { weight: nil, date: @weight_entry.date }
        }
        assert_equal original_weight, @weight_entry.reload.weight
      end

      it "renders edit with unprocessable entity status" do
        patch weight_entry_path @weight_entry, params: {
          weight_entry: { weight: nil, date: @weight_entry.date }
        }
        assert_response :unprocessable_entity
      end

      it "won't edit another user's weight entry" do
        not_own_weight_entry = users(:two).weight_entries.first
        patch weight_entry_path not_own_weight_entry, params: {
          weight_entry: { weight: 180.2, date: not_own_weight_entry.date }
        }
        assert_response :not_found
      end
    end
  end

  describe "#destroy" do
    context "with valid params" do
      it "deletes the weight entry" do
        assert_difference("WeightEntry.count", -1) do
          delete weight_entry_path @weight_entry
        end
      end

      it "redirects to the day page after a successful deletion" do
        date = @weight_entry.date
        delete weight_entry_path @weight_entry
        assert_redirected_to day_path_for(date)
      end
    end

    context "with invalid params" do
      it "won't delete another user's weight entry" do
        not_own_weight_entry = users(:two).weight_entries.first
        delete weight_entry_path not_own_weight_entry
        assert_response :not_found
      end
    end
  end
end
