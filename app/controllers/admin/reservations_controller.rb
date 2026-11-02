module Admin
  class ReservationsController < BaseController
    before_action :set_reservation, only: %i[confirm decline cancel complete extend record_on_site]

    def index
      scope = policy_scope(Reservation).includes(:zone, :user)
      scope = scope.where(status: params[:status]) if Reservation.statuses.key?(params[:status])
      scope = scope.where(zone_id: params[:zone_id]) if params[:zone_id].present?
      @reservations = scope.order(starts_at: :desc).limit(200).includes(:payments)
      @zones = Zone.ordered
    end

    def confirm
      authorize @reservation
      @reservation.confirm!
      ReservationMailer.with(reservation: @reservation).confirmed.deliver_later
      redirect_to admin_reservations_path, notice: t(".confirmed", name: @reservation.user)
    rescue ActiveRecord::RecordInvalid
      redirect_to admin_reservations_path, alert: @reservation.errors.full_messages.to_sentence
    end

    def decline
      authorize @reservation
      @reservation.decline!(note: params[:review_note].presence || t(".default_note"))
      ReservationMailer.with(reservation: @reservation).declined.deliver_later
      redirect_to admin_reservations_path, notice: t(".declined", name: @reservation.user)
    rescue ActiveRecord::RecordInvalid
      redirect_to admin_reservations_path, alert: @reservation.errors.full_messages.to_sentence
    end

    def cancel
      authorize @reservation
      @reservation.cancel!
      redirect_to admin_reservations_path, notice: t(".cancelled", name: @reservation.user)
    rescue ActiveRecord::RecordInvalid
      redirect_to admin_reservations_path, alert: @reservation.errors.full_messages.to_sentence
    end

    def complete
      authorize @reservation
      @reservation.complete!
      redirect_to admin_reservations_path, notice: t(".completed", name: @reservation.user)
    rescue ActiveRecord::RecordInvalid
      redirect_to admin_reservations_path, alert: @reservation.errors.full_messages.to_sentence
    end

    # Продление на месте: шаг 30 минут по умолчанию
    def extend
      authorize @reservation
      minutes = params.fetch(:minutes, 30).to_i
      @reservation.extend!(minutes)
      redirect_to admin_reservations_path, notice: t(".extended", minutes:, total: view_context.money(@reservation.total_price_cents))
    rescue ActiveRecord::RecordInvalid
      redirect_to admin_reservations_path, alert: @reservation.errors.full_messages.to_sentence
    end

    # Оплата на месте (наличные/карта на ресепшене) — вопрос 7 чек-листа bePaid-демо
    def record_on_site
      authorize @reservation
      @reservation.payments.create!(
        tracking_id: "polaris-cash-rs-#{@reservation.id}-#{SecureRandom.hex(6)}",
        amount_cents: @reservation.total_price_cents,
        status: :successful,
        method: :on_site,
        paid_at: Time.current,
        test: false,
        raw_response: { recorded_by: current_user.id, at: Time.current.iso8601 }
      )
      redirect_to admin_reservations_path, notice: t(".recorded_on_site", name: @reservation.user)
    rescue ActiveRecord::RecordInvalid
      redirect_to admin_reservations_path, alert: @reservation.errors.full_messages.to_sentence
    end

    private

    def set_reservation
      @reservation = Reservation.find(params[:id])
    end
  end
end
