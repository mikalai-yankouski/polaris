class CreateZoneAdjacencies < ActiveRecord::Migration[8.1]
  def change
    # Смежные комнаты (для правила «караоке-брони не в соседних комнатах»)
    create_table :zone_adjacencies do |t|
      t.references :zone, null: false, foreign_key: true
      t.references :adjacent_zone, null: false, foreign_key: { to_table: :zones }

      t.timestamps
    end
    add_index :zone_adjacencies, [ :zone_id, :adjacent_zone_id ], unique: true
  end
end
