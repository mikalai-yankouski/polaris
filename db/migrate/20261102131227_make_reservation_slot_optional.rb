class MakeReservationSlotOptional < ActiveRecord::Migration[8.1]
  # Заявка может прийти без времени: гость оставляет дату и телефон,
  # слот согласовывается по телефону. Заявки без слота (starts_at/ends_at NULL)
  # не пересекаются по exclusion constraint (tsrange от NULL даёт NULL).
  def change
    change_column_null :reservations, :starts_at, true
    change_column_null :reservations, :ends_at, true
  end
end
