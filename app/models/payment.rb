class Payment < ApplicationRecord
  belongs_to :reservation

  enum :status, { pending: 0, successful: 1, failed: 2 }, default: :pending
  enum :method, { online: 0, on_site: 1 }, default: :online

  validates :tracking_id, presence: true, uniqueness: true
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, presence: true

  scope :successful, -> { where(status: statuses[:successful]) }
  scope :online, -> { where(method: methods[:online]) }

  def status_label
    I18n.t(status, scope: "payment_statuses", default: status.to_s.humanize)
  end
end
