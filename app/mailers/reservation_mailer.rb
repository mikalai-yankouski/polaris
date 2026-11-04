class ReservationMailer < ApplicationMailer
  helper :application

  # Гостевые брони (без пользователя) идут без email — письма не отправляем
  def self.deliver_if_user(reservation, action)
    mail = with(reservation:).public_send(action)
    mail&.deliver_later
  end

  def submitted
    mail_to_user t(".subject", zone: reservation.zone)
  end

  def confirmed
    mail_to_user t(".subject", zone: reservation.zone)
  end

  def declined
    mail_to_user t(".subject", zone: reservation.zone)
  end

  def reminder
    mail_to_user t(".subject", zone: reservation.zone)
  end

  def paid
    mail_to_user t(".subject", zone: reservation.zone)
  end

  private

    def reservation
      @reservation ||= params[:reservation]
    end

    def mail_to_user(subject)
      return nil if reservation.user.blank?

      mail to: reservation.user.email_address, subject:
    end
end
