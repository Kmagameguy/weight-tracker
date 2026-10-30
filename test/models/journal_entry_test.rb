require "test_helper"

class JournalEntryTest < ActiveSupport::TestCase
  describe "#validations" do
    it "is valid with valid attributes" do
      journal_entry = journal_entries(:one)
      assert_predicate journal_entry, :valid?
    end

    it "can be empty" do
      journal_entry = journal_entries(:one)
      journal_entry.note = nil

      assert_predicate journal_entry, :valid?
    end

    it "is invalid when the note is too long" do
      journal_entry = journal_entries(:one)
      journal_entry.note = "a" * (JournalEntry::MAX_NOTE_LENGTH + 1)

      assert_not_predicate journal_entry, :valid?
      assert_includes journal_entry.errors[:note], "is too long (maximum is #{JournalEntry::MAX_NOTE_LENGTH} characters)"
    end

    it "is invalid without a date" do
      journal_entry = journal_entries(:one)
      journal_entry.date = nil

      assert_not_predicate journal_entry, :valid?
      assert_includes journal_entry.errors[:date], "can't be blank"
    end

    it "is invalid if a journal entry already exists for the given date and user" do
      existing_entry = journal_entries(:one)
      duplicate_entry = JournalEntry.new(date: existing_entry.date, user: existing_entry.user, note: "Another one")

      assert_not_predicate duplicate_entry, :valid?
      assert_includes duplicate_entry.errors[:date], "already has a journal entry"
    end

    it "allows different users to have an entry on the same date" do
      existing_entry = journal_entries(:one)
      new_entry = JournalEntry.new(date: existing_entry.date, user: users(:two), note: "Same day, different user")

      assert_predicate new_entry, :valid?
    end

    it "is invalid without a user reference" do
      journal_entry = journal_entries(:one)
      journal_entry.user = nil

      assert_not_predicate journal_entry, :valid?
      assert_includes journal_entry.errors[:user], "must exist"
    end
  end
end
