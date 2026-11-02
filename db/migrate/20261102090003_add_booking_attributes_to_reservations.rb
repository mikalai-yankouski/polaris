class AddBookingAttributesToReservations < ActiveRecord::Migration[8.1]
  def change
    # Детское мероприятие: буфер уборки 30 минут вместо стандартного
    add_column :reservations, :children_party, :boolean, null: false, default: false
    # Снапшот буфера уборки на момент создания брони
    add_column :reservations, :cleaning_minutes, :integer, null: false, default: 15

    # Окно блокировки комнаты теперь включает уборку: [starts_at, ends_at + cleaning_minutes)
    remove_exclusion_constraint :reservations, name: "reservations_no_overlaps"
    add_exclusion_constraint :reservations,
                             "zone_id WITH =, tsrange(starts_at, ends_at + make_interval(mins => cleaning_minutes), '[)') WITH &&",
                             using: :gist,
                             where: "status IN (0, 1)",
                             name: "reservations_no_overlaps"
  end
end
