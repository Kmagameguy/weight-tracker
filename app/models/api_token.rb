class ApiToken < ApplicationRecord
  belongs_to :user

  def self.issue_for(user, name: nil)
    raw = SecureRandom.urlsafe_base64(32)
    create!(user: user, name: name, token_digest: digest(raw))
    raw
  end

  def self.authenticate(raw)
    return if raw.blank?

    find_by(token_digest: digest(raw))
  end

  def self.digest(raw)
    Digest::SHA256.hexdigest(raw)
  end
end
