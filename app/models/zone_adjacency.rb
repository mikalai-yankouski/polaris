class ZoneAdjacency < ApplicationRecord
  belongs_to :zone
  belongs_to :adjacent_zone, class_name: "Zone"
end
