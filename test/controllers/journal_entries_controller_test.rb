require "test_helper"

class JournalEntriesControllerTest < ActionDispatch::IntegrationTest
  include RoutingHelper

  setup do
    @user = users(:one)
    sign_in_as(@user)
    @journal_entry = @user.journal_entries.first
  end

  describe "#authentication" do
    before { sign_out }

    it "redirects unauthenticated users away from #create" do
      assert_no_difference("JournalEntry.count") do
        post journal_entries_path, params: { journal_entry: { note: "Hi", date: Date.current } }
      end

      assert_redirected_to new_session_path
    end

    it "redirects unauthenticated users away from #edit" do
      get edit_journal_entry_path @journal_entry

      assert_redirected_to new_session_path
    end

    it "redirects unauthenticated users away from #update" do
      patch journal_entry_path(@journal_entry), params: { journal_entry: { note: "Hacked!!!" } }

      assert_redirected_to new_session_path
      assert_not_equal "Hacked!!!", @journal_entry.reload.note
    end

    it "redirects unauthenticated users away from the destroy action" do
      assert_no_difference("JournalEntry.count") do
        delete journal_entry_path @journal_entry
      end

      assert_redirected_to new_session_path
    end
  end

  describe "#create" do
    context "with valid params" do
      before { @user.journal_entries.destroy_all }

      it "creates a new journal entry" do
        assert_difference("JournalEntry.count", 1) do
          post journal_entries_path, params: { journal_entry: { note: "Productive day.", date: Date.current } }
        end
      end

      it "redirects to the day page after creation" do
        post journal_entries_path, params: { journal_entry: { note: "Productive day.", date: Date.current } }

        assert_redirected_to day_path_for(JournalEntry.order(:created_at).last)
      end

      it "scopes the journal entry to the logged-in user" do
        post journal_entries_path, params: { journal_entry: { note: "Productive day.", date: Date.current } }

        assert_equal @user.id, JournalEntry.order(:created_at).last.user_id
      end
    end

    context "with invalid params" do
      it "does not create a journal entry" do
        assert_no_difference("JournalEntry.count") do
          post journal_entries_path, params: {
            journal_entry: { note: "a" * (JournalEntry::MAX_NOTE_LENGTH + 1), date: Date.current }
          }
        end

        assert_redirected_to day_path_for(Date.current)
        follow_redirect!
        assert_select ".bg-red-50", text: "Note is too long (maximum is #{JournalEntry::MAX_NOTE_LENGTH} characters)"
      end

      it "does not allow a second entry on the same day" do
        assert_no_difference("JournalEntry.count") do
          post journal_entries_path, params: { journal_entry: { note: "Again!", date: @journal_entry.date } }
        end
      end

      it "redirects back to the day page with an alert" do
        post journal_entries_path, params: { journal_entry: { note: "a" * (JournalEntry::MAX_NOTE_LENGTH + 1), date: Date.current } }

        assert_redirected_to day_path_for(Date.current)
        follow_redirect!
        assert_select ".bg-red-50", text: "Note is too long (maximum is #{JournalEntry::MAX_NOTE_LENGTH} characters)"
      end
    end
  end

  describe "#edit" do
    it "renders the form inside the turbo frame successfully" do
      get edit_journal_entry_path @journal_entry

      assert_response :success
      assert_select "turbo-frame#journal_entry"
      assert_select "turbo-frame#journal_entry textarea"
    end

    it "won't edit another user's journal entry" do
      get edit_journal_entry_path users(:two).journal_entries.first

      assert_response :not_found
    end
  end

  describe "#update" do
    context "with valid params" do
      it "updates the journal entry" do
        patch journal_entry_path(@journal_entry), params: {
          journal_entry: { note: "Edited thoughts", date: @journal_entry.date }
        }

        assert_equal "Edited thoughts", @journal_entry.reload.note
      end

      it "redirects to the day page after a successful update" do
        patch journal_entry_path(@journal_entry), params: {
          journal_entry: { note: "Edited thoughts", date: @journal_entry.date }
        }

        assert_redirected_to day_path_for(@journal_entry.reload)
      end
    end

    context "with invalid params" do
      it "does not update the journal entry" do
        original_note = @journal_entry.note
        patch journal_entry_path(@journal_entry), params: {
          journal_entry: { note: "a" * (JournalEntry::MAX_NOTE_LENGTH + 1), date: @journal_entry.date }
        }

        assert_response :unprocessable_entity
        assert_equal original_note, @journal_entry.reload.note
      end

      it "won't update another user's journal entry" do
        other_entry = users(:two).journal_entries.first
        other_entry_note = other_entry.note
        patch journal_entry_path(other_entry), params: {
          journal_entry: { note: "Hacked!!!", date: other_entry.date }
        }

        assert_response :not_found
        assert_equal other_entry_note, other_entry.reload.note
      end
    end
  end

  describe "#destroy" do
    it "deletes the journal entry" do
      assert_difference("JournalEntry.count", -1) do
        delete journal_entry_path @journal_entry
      end
    end

    it "redirects to the day page after a successful deletion" do
      date = @journal_entry.date
      delete journal_entry_path @journal_entry

      assert_redirected_to day_path_for(date)
    end

    it "won't delete another user's journal entry" do
      assert_no_difference("JournalEntry.count") do
        delete journal_entry_path users(:two).journal_entries.first
      end

      assert_response :not_found
    end
  end
end
