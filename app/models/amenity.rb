class Amenity < ApplicationRecord
  has_many :zone_amenities, dependent: :destroy
  has_many :zones, through: :zone_amenities

  scope :ordered, -> { order(:name) }

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def to_s = name
end
