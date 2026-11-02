class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string, null: false, default: ""
    add_column :users, :phone, :string
    add_column :users, :role, :integer, null: false, default: 0
  end
end
