require "test_helper"

class TagTest < ActiveSupport::TestCase
  describe "#validations" do
    it "is valid with valid attributes" do
      assert_predicate tags(:headache), :valid?
    end

    it "is invalid without a name" do
      tag = tags(:headache)
      tag.name = nil

      assert_not_predicate tag, :valid?
      assert_includes tag.errors[:name], "can't be blank"
    end

    it "is invalid with a name longer than #{::Tag::MAX_NAME_LENGTH}" do
      tag = tags(:headache)
      tag.name = "a" * (::Tag::MAX_NAME_LENGTH + 1)

      assert_operator ::Tag::MAX_NAME_LENGTH, :>, 0
      assert_not_predicate tag, :valid?
    end

    it "is invalid with a duplicate name (case-insensitive) for the same user" do
      duplicate_tag = tags(:headache).dup
      duplicate_tag.name = duplicate_tag.name.upcase

      assert_not_predicate duplicate_tag, :valid?
      assert_includes duplicate_tag.errors[:name], "already exists"
    end

    it "allows two users to have a tag with the same name" do
      user_one = tags(:headache)
      assert_predicate Tag.new(user: users(:two), name: "Headache"), :valid?
    end

    it "is invalid without a user" do
      tag = tags(:headache)
      tag.user = nil

      assert_not_predicate tag, :valid?
      assert_includes tag.errors[:user], "must exist"
    end
  end

  describe "#normalizations" do
    it "squishes whitespace" do
      assert_equal "Bad Headache", Tag.new(name: "   Bad     Headache    ").name
    end
  end

  describe "#associations" do
    it "destroys dependent day tags" do
      tag = tags(:headache)

      assert_difference("DayTag.count", -tag.day_tags.count) { tag.destroy }
    end
  end
end
