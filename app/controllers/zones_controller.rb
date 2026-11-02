class ZonesController < ApplicationController
  allow_unauthenticated_access(only: %i[index show])
  before_action :set_zone, only: :show

  def index
    @zones = policy_scope(Zone)
  end

  def show
    authorize @zone
    @reservations = @zone.reservations.blocking
                         .where(starts_at: Time.current..)
                         .order(:starts_at)
                         .limit(50)
    @reservation = Reservation.new(zone: @zone)
  end

  private

    def set_zone
      @zone = Zone.find(params[:id])
    end
end
