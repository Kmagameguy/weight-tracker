require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  describe "#new" do
    it "shows the new session path" do
      get new_session_path
      assert_response :success
    end
  end

  describe "#create" do
    it "creates a new cookie-based session with valid credentials and redirects to root path" do
      post session_path, params: { email_address: @user.email_address, password: "password" }

      assert_redirected_to root_path
      assert cookies[:session_id]
    end

    it "does not create a session and rediriects back to the new session path with invalid credentials" do
      post session_path, params: { email_address: @user.email_address, password: "wrong" }

      assert_redirected_to new_session_path
      assert_nil cookies[:session_id]
    end
  end

  describe "#destroy" do
    it "empties the session cookie and redirects to the new session path" do
      sign_in_as(User.take)

      delete session_path

      assert_redirected_to new_session_path
      assert_empty cookies[:session_id]
    end
  end
end
