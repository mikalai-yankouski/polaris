class ReservationsController < ApplicationController
  # Гость бронирует без аккаунта; управление бронями — только в админке
  allow_unauthenticated_access only: :create

  def create
    @zone = Zone.active.find(params[:zone_id])
    @reservation = Reservation.new(reservation_params.merge(zone: @zone, user: current_user))
    authorize @reservation

    if @reservation.save
      ReservationMailer.deliver_if_user(@reservation, :submitted)

      # Предоплата: сразу уводим на страницу bePaid (если настроен и слот известен).
      # Возврат — на страницу зоны: управление бронями доступно только персоналу
      if Bepaid::Config.configured? && @reservation.payable?
        result = Payments::Checkout.call(
          reservation: @reservation,
          return_url: zone_url(@zone),
          notification_url: bepaid_webhook_url
        )
        if result.success?
          redirect_to result.redirect_url, allow_other_host: true
          return
        end
      end

      redirect_to @zone, notice: @reservation.slot? ? t(".created") : t(".created_slotless")
    else
      render "zones/show", status: :unprocessable_entity
    end
  rescue ActiveRecord::StatementInvalid => e
    # Пересечение поймано exclusion constraint на уровне БД (гонка)
    raise unless e.cause.is_a?(PG::ExclusionViolation)

    @reservation.errors.add(:starts_at, :slot_taken)
    render "zones/show", status: :unprocessable_entity
  end

  private

    def reservation_params
      permitted = params.require(:reservation)
                         .permit(:booking_date, :start_time, :booking_duration, :guests_count,
                                 :purpose, :children_party, :guest_name, :guest_phone)
      permitted[:requested_date] = permitted_date
      permitted.merge!(slot_params)
    end

    # Слот собираем из даты и времени начала; время не обязательно —
    # без него заявка уходит персоналу на согласование по телефону
    def slot_params
      date = permitted_date
      time = params.dig(:reservation, :start_time).presence
      return {} if date.blank? || time.blank?

      duration = params.dig(:reservation, :booking_duration).presence&.to_i || @zone.min_duration_minutes
      starts_at = date.beginning_of_day + Time.parse(time).seconds_since_midnight.seconds
      { starts_at:, ends_at: starts_at + duration.minutes }
    end

    def permitted_date
      Date.parse(params.dig(:reservation, :booking_date).to_s)
    rescue ArgumentError, TypeError
      nil
    end
end
