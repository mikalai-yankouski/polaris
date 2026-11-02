class Building < ApplicationRecord
  has_many :zones, dependent: :destroy

  validates :name, presence: true

  def to_s = name
end
