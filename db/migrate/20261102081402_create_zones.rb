class CreateZones < ActiveRecord::Migration[8.1]
  def change
    create_table :zones do |t|
      t.references :building, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :capacity, null: false, default: 1
      t.integer :floor, null: false, default: 1
      t.integer :hourly_rate_cents, null: false, default: 0
      t.integer :min_duration_minutes, null: false, default: 60
      t.integer :max_duration_minutes, null: false, default: 480
      t.boolean :requires_approval, null: false, default: true
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :zones, :name, unique: true
  end
end
