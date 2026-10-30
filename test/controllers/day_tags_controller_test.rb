require "test_helper"

class DayTagsControllerTest < ActionDispatch::IntegrationTest
  include RoutingHelper

  setup do
    @user = users(:one)
    sign_in_as(@user)
    @tag  = tags(:headache)
    @date = Date.parse("2026-06-06")
  end

  describe "#authentication" do
    before { sign_out }

    it "redirects unauthenticated users away from #create" do
      assert_no_difference("DayTag.count") do
        post day_tags_path, params: { day_tag: { tag_id: @tag.id, date: @date } }
      end

      assert_redirected_to new_session_path
    end
  end

  describe "#create" do
    it "applies the tag to the day" do
      assert_difference("DayTag.count", 1) do
        post day_tags_path, params: { day_tag: { tag_id: @tag.id, date: @date } }, as: :turbo_stream
      end

      assert_select "turbo-stream[action=replace][target=day_tags]"
    end

    it "is idempotent" do
      day_tag = day_tags(:headache_on_june_fifth)
      assert_no_difference("DayTag.count") do
        post day_tags_path, params: { day_tag: { tag_id: @tag.id, date: day_tag.date } }, as: :turbo_stream
      end
    end

    it "redirects to the day page for html requests" do
      post day_tags_path, params: { day_tag: { tag_id: @tag.id, date: @date } }

      assert_redirected_to day_path_for(@date)
    end

    it "won't tag a day with another user's tag" do
      assert_no_difference("DayTag.count") do
        post day_tags_path, params: { day_tag: { tag_id: users(:two).tags.first.id, date: @date } }
      end

      assert_response :not_found
    end

    it "rejects an invalid date" do
      assert_no_difference("DayTag.count") do
        post day_tags_path, params: { day_tag: { tag_id: @tag.id, date: "not-a-parseable-date" } }
      end

      assert_response :unprocessable_entity
    end
  end

  describe "#destroy" do
    it "removes the tag from teh day" do
      day_tag = day_tags(:headache_on_june_fifth)
      assert_difference("DayTag.count", -1) do
        delete day_tag_path(day_tag), as: :turbo_stream
      end

      assert_select "turbo-stream[action=replace][target=day_tags]"
    end

    it "won't remove another uer's day tag" do
      other_tag = users(:two).tags.first.day_tags.create!(date: @date)
      assert_no_difference("DayTag.count") do
        delete day_tag_path(other_tag)
      end

      assert_response :not_found
    end
  end
end
