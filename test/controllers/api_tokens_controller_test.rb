require "test_helper"

class ApiTokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  it "revokes one of the user's tokens" do
    ApiToken.issue_for(@user, name: "Pixel")

    assert_difference("ApiToken.count", -1) { delete api_token_path(@user.api_tokens.last) }
    assert_redirected_to profile_path
  end

  it "won't revoke another user's token" do
    ApiToken.issue_for(users(:two))

    assert_no_difference("ApiToken.count") { delete api_token_path(users(:two).api_tokens.last) }
    assert_response :not_found
  end

  it "revokes every token for the user, and only the user" do
    2.times { ApiToken.issue_for(@user) }
    ApiToken.issue_for(users(:two))

    assert_difference("ApiToken.count", -2) { delete destroy_all_api_tokens_path }
    assert_equal 1, users(:two).api_tokens.count
  end
end
