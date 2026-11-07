require "test_helper"

class Api::V1::SyncControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user  = users(:one)
    @token = ApiToken.issue_for(@user)
  end

  def sync(body, token: @token)
    post api_v1_sync_path, params: body, as: :json, headers: { "Authorization" => "Bearer #{token}" }
  end

  describe "authentication" do
    it "rejects requests without a valid token" do
      sync({ changes: [] }, token: nil)

      assert_response :unauthorized
    end
  end

  describe "pushing changes" do
    it "creates a record from an upsert, keeping the phone's uuid" do
      uuid   = SecureRandom.uuid
      change = {
        type: "food_entry",
        op: "upsert",
        uuid: uuid,
        name: "Toast",
        calories: 90,
        date: "2026-11-05",
        client_updated_at: Time.current.iso8601(6)
      }

      assert_difference("@user.food_entries.count", 1) { sync({ changes: [ change ] }) }
      assert_equal uuid, @user.food_entries.find_by(name: "Toast").uuid
    end

    it "keeps the server's record when there's a collision" do
      existing   = weight_entries(:one)
      phone_uuid = SecureRandom.uuid
      change     = {
        type: "weight_entry",
        op: "upsert",
        uuid: phone_uuid,
        weight: "200.0",
        date: existing.date.to_s,
        client_updated_at: 1.minute.ago.iso8601(6)
      }

      assert_no_difference("WeightEntry.count") { sync({ changes: [ change ] }) }
      deletes = response.parsed_body["changes"].select { it["op"] == "delete" }
      assert_includes deletes.map { it["uuid"] }, phone_uuid
    end

    it "won't delete records for a different user" do
      other_user_entry = food_entries(:salad)

      assert_no_difference("FoodEntry.count") do
        sync({ changes: [ { type: "food_entry", op: "delete", uuid: other_user_entry.uuid } ] })
      end
    end
  end

  describe "pulling changes" do
    it "returns sentinels for records destroyed on the server" do
      entry = food_entries(:burrito)
      expected_response = {
        "op"   => "delete",
        "type" => "food_entry",
        "uuid" => entry.uuid
      }

      entry.destroy!
      sync({ changes: [] })

      assert_includes response.parsed_body["changes"], expected_response
    end
  end
end
