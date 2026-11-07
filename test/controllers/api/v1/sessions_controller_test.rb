require "test_helper"

class Api::V1::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  def login(password: "password")
    post api_v1_session_path,
      params: { email_address: @user.email_address, password: password, device_name: "Pixel" },
      as: :json
  end

  describe "#create" do
    it "issues a prefixed token for gvalid credentials" do
      assert_difference("ApiToken.count", 1) { login }

      assert_response :created
      assert_predicate response.parsed_body["token"], :present?
      assert response.parsed_body["token"].start_with?(ApiToken::PREFIX)
    end

    it "issues a new token on every login" do
      assert_difference("ApiToken.count", 2) { 2.times { login } }
    end

    it "records the device name" do
      login

      assert_equal "Pixel", @user.api_tokens.last.name
    end

    it "rejects a wrong password" do
      assert_no_difference("ApiToken.count") { login(password: "wrong") }
      assert_response :unauthorized
    end
  end

  describe "#destroy" do
    it "revokes the calling token" do
      raw = ApiToken.issue_for(@user)

      assert_difference("ApiToken.count", -1) do
        delete api_v1_session_path, headers: { "Authorization" => "Bearer #{raw}" }
      end

      assert_response :no_content
      assert_nil ApiToken.authenticate(raw)
    end

    it "requires a token" do
      delete api_v1_session_path
      assert_response :unauthorized
    end
  end
end
