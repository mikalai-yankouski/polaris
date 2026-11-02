class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :reservations, dependent: :destroy

  enum :role, { member: 0, manager: 1, admin: 2 }, default: :member

  normalizes :email_address, with: ->(email) { email.strip.downcase }
  normalizes :phone, with: ->(phone) { phone.strip }

  validates :name, presence: true
  validates :phone, format: { with: /\A\+?[\d\s\-()]{7,}\z/ }, allow_blank: true

  scope :ordered, -> { order(:name) }

  def staff? = manager? || admin?

  def to_s = name.presence || email_address
end
