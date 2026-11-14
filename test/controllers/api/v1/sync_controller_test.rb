require "test_helper"

class Api::V1::SyncControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user  = users(:one)
    @token = ApiToken.issue_for(@user)
  end

  def sync(body, token: @token)
    headers = token ? { "Authorization" => "Bearer #{token}" } : {}
    post api_v1_sync_path, params: body, as: :json, headers: headers
  end

  def food_change(uuid = SecureRandom.uuid, **overrides)
    {
      type: "food_entry",
      op: "upsert",
      uuid: uuid,
      name: "Bread",
      calories: 111,
      date: Date.current.iso8601,
      client_updated_at: Time.current.iso8601(6)
    }.merge(overrides)
  end

  it "requires a valid token" do
    sync({ changes: [] }, token: nil)
    assert_response :unauthorized

    sync({ changes: [] }, token: "wt_bogus")
    assert_response :unauthorized
  end

  it "forbids caching" do
    uuid = SecureRandom.uuid
    sync({ changes: [ food_change(uuid) ] })

    assert_response :success
    assert_includes response.headers["Cache-Control"], "no-store"
    assert_includes response.headers["Pragma"], "no-cache"
  end

  it "publishes changes to the server" do
    uuid = SecureRandom.uuid
    sync({ changes: [ food_change(uuid) ] })

    assert_response :success
    body = response.parsed_body

    assert_equal [ uuid ], body["changes"].map { |change| change["uuid"] }
    assert_empty body["rejected"]
  end

  it "returns the user's settings during a sync event" do
    uuid = SecureRandom.uuid
    sync({ changes: [ food_change(uuid) ] })

    assert_response :success
    body = response.parsed_body

    assert_equal 1_500, body.dig("user", "daily_calorie_goal")
    assert_equal "America/New_York", body.dig("user", "timezone")
  end

  it "does nothing with an empty changeset" do
    uuid = SecureRandom.uuid
    sync({ changes: [ food_change(uuid) ] })

    assert_response :success
    body = response.parsed_body
    assert_not_empty body["changes"]

    sync({ cursor: body["cursor"], changes: [] })
    assert_empty response.parsed_body["changes"]
  end

  it "only syncs the data of the user associated with the token" do
    users(:two).food_entries.create!(name: "bar", calories: 12, date: Date.current)
    token_user_entry = @user.food_entries.create!(name: "foo", calories: 9, date: Date.current)

    sync({ changes: [] })

    assert_equal [ token_user_entry.uuid ], response.parsed_body["changes"].map { |change| change["uuid"] }
  end

  it "rejects changes with a code without blocking the rest of the payload" do
    sync({ changes: [ food_change(name: ""), food_change ] })

    assert_response :success
    assert_equal [ "invalid" ], response.parsed_body["rejected"].map { |rejection| rejection["code"] }
  end

  it "rejects an invalid cursor" do
    sync({ cursor: "999999999", changes: [] })

    assert_response :conflict
    assert_equal "cursor_reset", response.parsed_body["error"]
  end

  it "refuses bad payloads entirely" do
    uuid = SecureRandom.uuid
    invalid_entries = [
      { changes: "nope" },
      { changes: { "0" => food_change(uuid) } },
      { changes: [ food_change(uuid), 7 ] }
    ]

    invalid_entries.each do |invalid_entry|
      sync(invalid_entry)
      assert_response :unprocessable_entity
    end

    assert_not FoodEntry.exists?(uuid: uuid)
  end

  it "rejects batches that are too large" do
    big_bad_batch = Array.new(SyncService::MAX_CHANGES + 1) do
      { type: "food_entry", op: "delete", uuid: SecureRandom.uuid }
    end

    sync({ changes: big_bad_batch })

    assert_response :content_too_large
  end

  it "rejects oversized payload entries" do
    sync({ changes: [], padding: "x" * (Api::V1::SyncController::MAX_BODY_SIZE + 1) })

    assert_response :content_too_large
  end
end
