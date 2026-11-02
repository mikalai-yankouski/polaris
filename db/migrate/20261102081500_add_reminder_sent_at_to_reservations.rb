class AddReminderSentAtToReservations < ActiveRecord::Migration[8.1]
  def change
    add_column :reservations, :reminder_sent_at, :datetime
  end
end
