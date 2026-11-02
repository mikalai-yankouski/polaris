module Admin
  class ReservationsController < BaseController
    before_action :set_reservation, only: %i[confirm decline cancel complete]

    def index
      scope = policy_scope(Reservation).includes(:zone, :user)
      scope = scope.where(status: params[:status]) if Reservation.statuses.key?(params[:status])
      scope = scope.where(zone_id: params[:zone_id]) if params[:zone_id].present?
      @reservations = scope.order(starts_at: :desc).limit(200)
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

    private

    def set_reservation
      @reservation = Reservation.find(params[:id])
    end
  end
end
