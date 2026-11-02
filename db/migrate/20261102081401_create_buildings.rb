class CreateBuildings < ActiveRecord::Migration[8.1]
  def change
    create_table :buildings do |t|
      t.string :name, null: false
      t.string :address
      t.text :description

      t.timestamps
    end
  end
end
