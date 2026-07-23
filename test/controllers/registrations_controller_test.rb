require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.take
    @valid_params = {
      email_address: "new_user@example.com",
      password: "password123",
      password_confirmation: "password123",
      daily_calorie_goal: User::DEFAULT_DAILY_CALORIE_GOAL,
      timezone: "Etc/UTC"
    }
  end

  describe "when already signed in" do
    before { sign_in_as(users(:one)) }

    it "redirects away from #new" do
      get new_registration_path
      assert_redirected_to root_path
    end

    it "redirects away from #create without creating a user" do
      assert_no_difference("User.count") do
        post registrations_path, params: { user: @valid_params }
      end

      assert_redirected_to root_path
    end
  end

  describe "#new" do
    it "shows the new registration path" do
      get new_registration_path
      assert_response :success
    end
  end

  describe "#create" do
    context "with valid params" do
      it "creates a new user" do
        assert_difference("User.count", 1) do
          post registrations_path, params: { user: @valid_params }
        end
      end

      it "signs the new user in" do
        post registrations_path, params: { user: @valid_params }
        assert cookies[:session_id]
      end

      it "redirects to root" do
        post registrations_path, params: { user: @valid_params }
        assert_redirected_to root_path
      end

      it "persists the submitted daily calorie goal and timezone" do
        post registrations_path, params: {
          user: @valid_params.merge(daily_calorie_goal: 1_800, timezone: "America/New_York")
        }

        new_user = User.order(:created_at).last

        assert_equal 1_800, new_user.daily_calorie_goal
        assert_equal "America/New_York", new_user.timezone
      end
    end

    context "with invalid params" do
      it "does not create a user when the password is too short" do
        assert_no_difference("User.count") do
          post registrations_path, params: {
            user: @valid_params.merge(password: "short", password_confirmation: "short")
          }
        end
      end

      it "does not create a user when the password confirmation does not match" do
        assert_no_difference("User.count") do
          post registrations_path, params: {
            user: @valid_params.merge(password_confirmation: "somethingelse")
          }
        end
      end

      it "does not create a user with a duplicate email address" do
        existing_user = users(:one)

        assert_no_difference("User.count") do
          post registrations_path, params: {
            user: @valid_params.merge(email_address: existing_user.email_address.upcase)
          }
        end
      end

      it "does not sign the user in" do
        post registrations_path, params: {
          user: @valid_params.merge(password: "short", password_confirmation: "short")
        }

        assert_nil cookies[:session_id]
      end

      it "shows the validation errors" do
        post registrations_path, params: {
          user: @valid_params.merge(password: "short", password_confirmation: "short")
        }

        assert_select ".bg-red-50", text: /Password is too short/
      end

      it "re-renders the #new template with an unprocessable_entity status" do
        post registrations_path, params: {
          user: @valid_params.merge(password: "short", password_confirmation: "short")
        }

        assert_response :unprocessable_entity
      end
    end
  end
end
