class MakeReservationUserOptionalAddGuestFields < ActiveRecord::Migration[8.1]
  def change
    # Клиенты бронируют без аккаунта — идентифицируем по имени и телефону
    change_column_null :reservations, :user_id, true
    add_column :reservations, :guest_name, :string
    add_column :reservations, :guest_phone, :string
    add_index :reservations, :guest_phone
  end
end
