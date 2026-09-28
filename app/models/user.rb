class User < ApplicationRecord
  has_secure_password

  has_many :hosted_lobbies, foreign_key: :host_id, dependent: :destroy
  has_many :games, dependent: :destroy

  before_validation :normalize_identity_fields

  validates :username, presence: true, uniqueness: { case_sensitive: false }, length: { in: 3..30 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8, maximum: 72 }, allow_nil: true

  private

  def normalize_identity_fields
    self.username = username.to_s.strip.downcase
    self.email = email.to_s.strip.downcase
  end
end
