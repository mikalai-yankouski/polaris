module Admin
  class ReservationsController < BaseController
    before_action :set_reservation, only: %i[confirm decline cancel complete extend record_on_site assign_time]

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
      ReservationMailer.deliver_if_user(@reservation, :confirmed)
      redirect_to admin_reservations_path, notice: t(".confirmed", name: @reservation.client_name)
    rescue ActiveRecord::RecordInvalid
      redirect_to admin_reservations_path, alert: @reservation.errors.full_messages.to_sentence
    end

    def decline
      authorize @reservation
      @reservation.decline!(note: params[:review_note].presence || t(".default_note"))
      ReservationMailer.deliver_if_user(@reservation, :declined)
      redirect_to admin_reservations_path, notice: t(".declined", name: @reservation.client_name)
    rescue ActiveRecord::RecordInvalid
      redirect_to admin_reservations_path, alert: @reservation.errors.full_messages.to_sentence
    end

    def cancel
      authorize @reservation
      @reservation.cancel!
      redirect_to admin_reservations_path, notice: t(".cancelled", name: @reservation.client_name)
    rescue ActiveRecord::RecordInvalid
      redirect_to admin_reservations_path, alert: @reservation.errors.full_messages.to_sentence
    end

    def complete
      authorize @reservation
      @reservation.complete!
      redirect_to admin_reservations_path, notice: t(".completed", name: @reservation.client_name)
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
      redirect_to admin_reservations_path, notice: t(".recorded_on_site", name: @reservation.client_name)
    rescue ActiveRecord::RecordInvalid
      redirect_to admin_reservations_path, alert: @reservation.errors.full_messages.to_sentence
    end

    # Заявка без времени: согласовали слот по телефону — назначаем и считаем цену
    def assign_time
      authorize @reservation
      starts_at = Time.zone.parse(params[:starts_at]) if params[:starts_at].present?
      duration = params[:duration_minutes].presence&.to_i
      if starts_at && duration
        @reservation.assign_slot!(starts_at:, duration_minutes: duration)
        redirect_to admin_reservations_path,
                    notice: t(".assigned", name: @reservation.client_name, starts: l(@reservation.starts_at, format: :short))
      else
        redirect_to admin_reservations_path, alert: t(".assign_invalid")
      end
    rescue ActiveRecord::RecordInvalid
      redirect_to admin_reservations_path, alert: @reservation.errors.full_messages.to_sentence
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.cause.is_a?(PG::ExclusionViolation)

      @reservation.errors.add(:starts_at, :slot_taken)
      redirect_to admin_reservations_path, alert: @reservation.errors.full_messages.to_sentence
    end

  private

    def set_reservation
      @reservation = Reservation.find(params[:id])
    end
  end
end
