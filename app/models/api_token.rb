# frozen_string_literal: true

# Represents a per-user, per-device token for the sync API.
#
# On the rails side we only store a SHA-256 digest. Tokens expire if they are:
#   - Unused for longer than the IDLE_TTL
#   - Issued on a date older than the MAX_LIFETIME
#   - The oldest unused token when a user exceeds the MAX_PER_USER token count
#   - Revoked by a user

class ApiToken < ApplicationRecord
  PREFIX       = "wt_"
  IDLE_TTL     = 60.days
  MAX_LIFETIME = 1.year
  MAX_PER_USER = 10
  COOLDOWN_FOR_TTL_REFRESH = 1.hour

  belongs_to :user

  validates :token_digest, presence: true
  validates :name, length: { maximum: 100 }

  scope :active, -> {
    where("COALESCE(last_used_at, created_at) > ?", IDLE_TTL.ago)
      .where("created_at > ?", MAX_LIFETIME.ago)
  }

  scope :expired, -> {
    where("COALESCE(last_used_at, created_at) <= ? OR created_at <= ?", IDLE_TTL.ago, MAX_LIFETIME.ago)
  }

  scope :recently_used, -> { order(Arel.sql("COALESCE(last_used_at, created_at) DESC")) }

  def self.issue_for(user, name: nil)
    raw = PREFIX + SecureRandom.urlsafe_base64(32)

    user.with_lock do
      token = create!(user: user, name: name, token_digest: digest(raw))
      prune_for(user, except: token.id)
    end

    raw
  end

  def self.authenticate(raw)
    return if raw.blank?
    return unless raw.start_with?(PREFIX)
    return unless raw.match?(/\Awt_[A-Za-z0-9_-]{43}\z/)

    active.find_by(token_digest: digest(raw))
  end

  def self.digest(raw)
    Digest::SHA256.hexdigest(raw)
  end

  def self.prune_for(user, except: nil)
    keep = user.api_tokens
               .active
               .recently_used
               .limit(MAX_PER_USER)
               .pluck(:id)
    user.api_tokens.where.not(id: [ *keep, except ].compact).delete_all
  end

  # This is what keeps track of token activation/usage.
  # Don't need to update this on every request so apply a small cooldown.
  def touch_last_used!
    return if last_used_at && last_used_at > COOLDOWN_FOR_TTL_REFRESH.ago

    update_column(:last_used_at, Time.current)
  end
end
