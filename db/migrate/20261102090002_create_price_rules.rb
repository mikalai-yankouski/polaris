class CreatePriceRules < ActiveRecord::Migration[8.1]
  def change
    # Тарифная сетка: комната × будни/выходные × интервал времени суток × ставка за час
    create_table :price_rules do |t|
      t.references :zone, null: false, foreign_key: true
      t.integer :day_kind, null: false, default: 0 # 0 — будни, 1 — выходные
      t.time :starts_at_time, null: false
      t.time :ends_at_time, null: false
      t.integer :hourly_rate_cents, null: false

      t.timestamps
    end
    add_index :price_rules, [ :zone_id, :day_kind ]
  end
end
