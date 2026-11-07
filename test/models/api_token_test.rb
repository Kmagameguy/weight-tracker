require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  describe ".authenticate" do
    it "finds a token by its raw value" do
      raw = ApiToken.issue_for(@user)

      assert_equal @user, ApiToken.authenticate(raw).user
    end

    it "never stores the raw token" do
      raw = ApiToken.issue_for(@user)

      assert_not_includes ApiToken.pluck(:token_digest), raw
    end

    it "returns nil for blank or unknown tokens" do
      [ nil, "", "wt_not-a-real-token" ].each do |invalid_token|
        assert_nil ApiToken.authenticate(invalid_token)
      end
    end

    it "rejects a token that has been unused too long" do
      raw = ApiToken.issue_for(@user)

      travel(ApiToken::IDLE_TTL + 1.day) { assert_nil ApiToken.authenticate(raw) }
    end

    it "rejects a token past its lifetime, even if it was recently used" do
      raw = ApiToken.issue_for(@user)

      travel(ApiToken::MAX_LIFETIME + 1.day) do
        ApiToken.update_all(last_used_at: Time.current)
        assert_nil ApiToken.authenticate(raw)
      end
    end
  end

  describe ".issue_for" do
    it "prepends a suffix to the token" do
      assert ApiToken.issue_for(@user).start_with?(ApiToken::PREFIX)
    end

    it "limits the number of tokens a user can create" do
      raws = Array.new(ApiToken::MAX_PER_USER + 3) { ApiToken.issue_for(@user) }

      assert_equal ApiToken::MAX_PER_USER, @user.api_tokens.count
      assert ApiToken.authenticate(raws.last)
      assert_nil ApiToken.authenticate(raws.first)
    end

    it "prunes expired tokens when issuing a new one" do
      stale_token = ApiToken.issue_for(@user)

      travel(ApiToken::IDLE_TTL + 1.day) do
        ApiToken.issue_for(@user)
        assert_nil ApiToken.find_by(token_digest: ApiToken.digest(stale_token))
      end
    end

    it "doesn't prune another user's tokens" do
      other_user_token = ApiToken.issue_for(users(:two))
      (ApiToken::MAX_PER_USER + 1).times { ApiToken.issue_for(@user) }

      assert ApiToken.authenticate(other_user_token)
    end
  end

  describe "#touch_last_used!" do
    it "records use once within the cooldown interval" do
      raw    = ApiToken.issue_for(@user)
      record = ApiToken.authenticate(raw)

      assert_changes -> { record.reload.last_used_at } do
        record.touch_last_used!
      end

      assert_no_changes -> { record.reload.last_used_at } do
        record.touch_last_used!
      end

      travel(ApiToken::COOLDOWN_FOR_TTL_REFRESH + 1.minute) do
        assert_changes -> { record.reload.last_used_at } do
          record.touch_last_used!
        end
      end
    end

    it "keeps a regularly used token alive past the idle limit" do
      raw = ApiToken.issue_for(@user)

      travel(ApiToken::IDLE_TTL - 1.day) { ApiToken.authenticate(raw).touch_last_used! }
      travel(ApiToken::IDLE_TTL + 1.day) { assert ApiToken.authenticate(raw) }
    end
  end
end
