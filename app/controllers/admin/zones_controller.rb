module Admin
  class ZonesController < BaseController
    before_action :set_zone, only: %i[edit update destroy]

    def index
      @zones = policy_scope(Zone).includes(:building)
    end

    def new
      @zone = Zone.new
      authorize @zone
    end

    def create
      @zone = Zone.new(zone_params)
      authorize @zone
      if @zone.save
        redirect_to admin_zones_path, notice: t(".created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @zone
    end

    def update
      authorize @zone
      if @zone.update(zone_params)
        redirect_to admin_zones_path, notice: t(".updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @zone
      @zone.destroy
      redirect_to admin_zones_path, notice: t(".destroyed")
    end

    private

    def zone_params
      params.require(:zone).permit(:building_id, :name, :description, :capacity, :floor,
                                   :hourly_rate_cents, :min_duration_minutes, :max_duration_minutes,
                                   :requires_approval, :active, amenity_ids: [], photos: [])
    end

    def set_zone
      @zone = Zone.find(params[:id])
    end
  end
end
