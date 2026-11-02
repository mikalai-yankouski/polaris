class ReservationMailer < ApplicationMailer
  helper :application

  def submitted
    @reservation = params[:reservation]
    mail to: @reservation.user.email_address, subject: t(".subject", zone: @reservation.zone)
  end

  def confirmed
    @reservation = params[:reservation]
    mail to: @reservation.user.email_address, subject: t(".subject", zone: @reservation.zone)
  end

  def declined
    @reservation = params[:reservation]
    mail to: @reservation.user.email_address, subject: t(".subject", zone: @reservation.zone)
  end

  def reminder
    @reservation = params[:reservation]
    mail to: @reservation.user.email_address, subject: t(".subject", zone: @reservation.zone)
  end
end
