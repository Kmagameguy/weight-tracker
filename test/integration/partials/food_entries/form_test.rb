require "test_helper"

module Partials
  module FoodEntries
    class FormTest < ActionView::TestCase
      it "renders the form with correct fields" do
        food_entry = FoodEntry.new
        render "food_entries/form", food_entry: food_entry

        assert_select "form"
        assert_select "input[name*='name']"
        assert_select "input[name*='calories']"
        assert_select "input[type='submit']"
      end

      describe "for a new food entry record" do
        it "shows an 'Add' label for the submit button" do
          food_entry = FoodEntry.new
          render "food_entries/form", food_entry: food_entry

          assert_select "input[type='submit'][value=?]", "Add"
        end
      end

      describe "for an existing food entry record" do
        it "shows an 'Update' label for the submit button" do
          food_entry = users(:one).food_entries.first
          render "food_entries/form", food_entry: food_entry

          assert_select "input[type='submit'][value=?]", "Update"
        end
      end
    end
  end
end
