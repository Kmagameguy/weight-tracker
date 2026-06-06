require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  describe "#new" do
    it "shows the new password path" do
      get new_password_path
      assert_response :success
    end
  end

  describe "#create" do
    it "sends a password reset email" do
      post passwords_path, params: { email_address: @user.email_address }
      assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
      assert_redirected_to new_session_path

      follow_redirect!
      assert_notice "reset instructions sent"
    end

    it "redirects but sends no mail for an unknown user" do
      post passwords_path, params: { email_address: "missing-user@example.com" }
      assert_enqueued_emails 0
      assert_redirected_to new_session_path

      follow_redirect!
      assert_notice "reset instructions sent"
    end
  end

  describe "#edit" do
    it "shows the edit password path" do
      get edit_password_path(@user.password_reset_token)
      assert_response :success
    end

    it "shows an error when the password reset token is invalid" do
      get edit_password_path("invalid token")
      assert_redirected_to new_password_path

      follow_redirect!
      assert_notice "reset link is invalid"
    end
  end

  describe "#update" do
    it "updates the user's password when valid" do
      assert_changes -> { @user.reload.password_digest } do
        put password_path(@user.password_reset_token), params: { password: "new", password_confirmation: "new" }
        assert_redirected_to new_session_path
      end

      follow_redirect!
      assert_notice "Password has been reset"
    end

    it "shows an error if password fields don't match" do
      token = @user.password_reset_token
      assert_no_changes -> { @user.reload.password_digest } do
        put password_path(token), params: { password: "no", password_confirmation: "match" }
        assert_redirected_to edit_password_path(token)
      end

      follow_redirect!
      assert_notice "Passwords did not match"
    end
  end

  private

  def assert_notice(text)
    assert_select "div", /#{text}/
  end
end
