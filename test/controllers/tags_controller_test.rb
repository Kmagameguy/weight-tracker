require "test_helper"

class TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  describe "#create" do
    it "creates a tag for the current user" do
      assert_difference("@user.tags.count", 1) do
        post tags_path, params: { tag: { name: "Migraine" } }
      end

      assert_redirected_to profile_path
    end

    it "redirects with an alert when invalid" do
      assert_no_difference("Tag.count") do
        post tags_path, params: { tag: { name: tags(:headache).name } }
      end

      assert_redirected_to profile_path
      follow_redirect!
      assert_select ".bg-red-50", text: /Name already exists/
    end
  end

  describe "#edit" do
    it "renders the edit form inside the tag's turbo frame" do
      tag = tags(:headache)
      get edit_tag_path(tag)

      assert_response :success
      assert_select "turbo-frame#tag_#{tag.id} form"
    end

    it "won't edit another user's tag" do
      get edit_tag_path(users(:two).tags.first)

      assert_response :not_found
    end
  end

  describe "#update" do
    it "renames the tag and redirects to the profile" do
      tag = tags(:headache)
      patch tag_path(tag), params: { tag: { name: "Migraine" } }

      assert_equal "Migraine", tag.reload.name
      assert_redirected_to profile_path
    end

    it "keeps the tag's day history when renamed" do
      tag = tags(:headache)
      assert_no_difference("DayTag.count") do
        patch tag_path(tag), params: { tag: { name: "Migraine" } }
      end

      assert_equal tag, day_tags(:headache_on_june_fifth).reload.tag
    end

    it "allows changing only the capitalization of a tag's own name" do
      tag = tags(:headache)
      upcased_name = tag.name.upcase
      assert_no_difference("DayTag.count") do
        patch tag_path(tag), params: { tag: { name: upcased_name } }
      end

      assert_equal upcased_name, tag.reload.name
    end

    it "redirects with an alert and leaves the name alone when blank" do
      tag = tags(:headache)
      patch tag_path(tag), params: { tag: { name: " " } }

      assert_equal "Headache", tag.reload.name
      assert_response :unprocessable_entity
    end

    it "rejects a name that is a duplicate of a user's existing tag" do
      @user.tags.create!(name: "Allergies")
      tag = tags(:headache)
      patch tag_path(tag), params: { tag: { name: "allergies" } }

      assert_response :unprocessable_entity
      assert_equal "Headache", tag.reload.name
      assert_select ".bg-red-50", text: /Name already exists/
    end

    it "won't update another user's tags" do
      other_tag = users(:two).tags.first
      other_tag_name = other_tag.name
      patch tag_path(other_tag), params: { tag: { name: "Hacked!!!" } }

      assert_response :not_found
      assert_equal other_tag_name, other_tag.reload.name
    end
  end

  describe "#destroy" do
    it "removes the tag" do
      assert_difference("Tag.count", -1) { delete tag_path(tags(:headache)) }
      assert_redirected_to profile_path
    end

    it "won't remove another user's tag" do
      assert_no_difference("Tag.count") { delete tag_path(users(:two).tags.first) }
      assert_response :not_found
    end
  end
end
