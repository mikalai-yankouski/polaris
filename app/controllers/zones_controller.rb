class ZonesController < ApplicationController
  allow_unauthenticated_access(only: %i[landing index show])
  before_action :set_zone, only: :show

  # Лендинг на корне: hero + тизер зон + преимущества
  def landing
    @zones = policy_scope(Zone)
  end

  # Полный каталог пространств
  def index
    @zones = policy_scope(Zone)
  end

  # Занятость зон видит только персонал в админке — на сайте её нет
  def show
    authorize @zone
    @reservation = Reservation.new(zone: @zone)
  end

  private

    def set_zone
      @zone = Zone.find(params[:id])
    end
end
