class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :reservation, null: false, foreign_key: true
      # Ключ связки с bePaid: создаётся до запроса чекаута, приходит в webhook
      t.string :tracking_id, null: false
      t.integer :status, null: false, default: 0 # pending / successful / failed
      t.integer :method, null: false, default: 0  # online / on_site
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "BYN"
      t.string :bepaid_uid
      t.boolean :test, null: false, default: true
      t.jsonb :raw_response, null: false, default: {}
      t.datetime :paid_at

      t.timestamps
    end
    add_index :payments, :tracking_id, unique: true
    add_index :payments, :status
  end
end
