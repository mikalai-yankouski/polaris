class PaymentsController < ApplicationController
  # Запуск оплаты брони: создаёт платёж и уводит на страницу bePaid
  def create
    @reservation = Reservation.find(params[:reservation_id])
    authorize @reservation, :pay?

    result = Payments::Checkout.call(
      reservation: @reservation,
      return_url: reservations_url,
      notification_url: bepaid_webhook_url
    )

    if result.success?
      redirect_to result.redirect_url, allow_other_host: true
    else
      redirect_to reservations_path, alert: result.message
    end
  end
end
