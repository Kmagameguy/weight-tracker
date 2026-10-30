# frozen_string_literal: true

class JournalEntry < ApplicationRecord
  MAX_NOTE_LENGTH = 10_000

  belongs_to :user, optional: false

  validates :note, length: { maximum: MAX_NOTE_LENGTH }
  validates :date, presence: true, uniqueness: { scope: :user_id, message: "already has a journal entry" }
end
