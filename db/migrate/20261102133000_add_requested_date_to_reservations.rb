class AddRequestedDateToReservations < ActiveRecord::Migration[8.1]
  # Желаемая дата из заявки без времени: слот согласуется по телефону
  def change
    add_column :reservations, :requested_date, :date
  end
end
