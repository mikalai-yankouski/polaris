class ReservationsController < ApplicationController
  before_action :set_reservation, only: :cancel

  def index
    @upcoming = policy_scope(Reservation).upcoming
    @past = policy_scope(Reservation).where.not(status: %w[pending confirmed]).order(starts_at: :desc)
  end

  def create
    @zone = Zone.active.find(params[:zone_id])
    @reservation = current_user.reservations.build(reservation_params.merge(zone: @zone))
    authorize @reservation

    if @reservation.save
      ReservationMailer.with(reservation: @reservation).submitted.deliver_later
      redirect_to reservations_path, notice: t(".created")
    else
      @reservations = @zone.reservations.blocking.where(starts_at: Time.current..).order(:starts_at).limit(50)
      render "zones/show", status: :unprocessable_entity
    end
  rescue ActiveRecord::StatementInvalid => e
    # Пересечение поймано exclusion constraint на уровне БД (гонка)
    raise unless e.cause.is_a?(PG::ExclusionViolation)

    @reservation.errors.add(:starts_at, :slot_taken)
    @reservations = @zone.reservations.blocking.where(starts_at: Time.current..).order(:starts_at).limit(50)
    render "zones/show", status: :unprocessable_entity
  end

  def cancel
    authorize @reservation
    @reservation.cancel!
    redirect_to reservations_path, notice: t(".cancelled")
  rescue ActiveRecord::RecordInvalid
    redirect_to reservations_path, alert: @reservation.errors.full_messages.to_sentence
  end

  private

    def reservation_params
      params.require(:reservation).permit(:starts_at, :ends_at, :guests_count, :purpose, :children_party)
    end

    def set_reservation
      @reservation = Reservation.find(params[:id])
    end
end
