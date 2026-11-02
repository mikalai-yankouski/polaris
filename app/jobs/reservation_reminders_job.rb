# Ежедневная задача: напоминает о подтверждённых бронях на ближайшие сутки.
class ReservationRemindersJob < ApplicationJob
  queue_as :default

  REMINDER_WINDOW_HOURS = 24

  def perform
    Reservation.confirmed
               .where(starts_at: Time.current..REMINDER_WINDOW_HOURS.hours.from_now)
               .where(reminder_sent_at: nil)
               .find_each do |reservation|
      ReservationMailer.with(reservation:).reminder.deliver_later
      reservation.touch(:reminder_sent_at)
    end
  end
end
