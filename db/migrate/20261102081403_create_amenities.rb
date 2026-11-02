class CreateAmenities < ActiveRecord::Migration[8.1]
  def change
    create_table :amenities do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :amenities, :name, unique: true

    create_table :zone_amenities do |t|
      t.references :zone, null: false, foreign_key: true
      t.references :amenity, null: false, foreign_key: true

      t.timestamps
    end
    add_index :zone_amenities, [ :zone_id, :amenity_id ], unique: true
  end
end
