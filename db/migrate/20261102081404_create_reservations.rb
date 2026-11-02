class CreateReservations < ActiveRecord::Migration[8.1]
  def change
    enable_extension "btree_gist"

    create_table :reservations do |t|
      t.references :zone, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :guests_count, null: false, default: 1
      t.text :purpose
      t.integer :status, null: false, default: 0
      t.integer :total_price_cents, null: false, default: 0
      t.text :review_note

      t.timestamps
    end
    add_index :reservations, [ :zone_id, :starts_at ]
    add_index :reservations, [ :user_id, :created_at ]
    add_index :reservations, :status

    # Гарантия отсутствия пересечений броней одной зоны на уровне БД:
    # активные брони (pending = 0, confirmed = 1) не могут пересекаться по времени.
    add_exclusion_constraint :reservations,
                             "zone_id WITH =, tsrange(starts_at, ends_at, '[)') WITH &&",
                             using: :gist,
                             where: "status IN (0, 1)",
                             name: "reservations_no_overlaps"
  end
end
