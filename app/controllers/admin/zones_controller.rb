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
        apply_photo_changes
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
      apply_photo_changes
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

    # Фото зала: догружаем новые, чистим отмеченные, запоминаем обложку.
    # Держим отдельно от zone_params, чтобы присвоение не затёрло существующие вложения.
    def apply_photo_changes
      @zone.photos.attach(params.dig(:zone, :photos).select(&:present?)) if params.dig(:zone, :photos).present?

      remove_ids = params.dig(:zone, :remove_photo_ids).to_a.reject(&:blank?).map(&:to_i)
      if remove_ids.present?
        @zone.photos.where(id: remove_ids).each(&:purge_later)
        @zone.cover_attachment_id = nil if remove_ids.include?(@zone.cover_attachment_id)
      end

      cover_id = params.dig(:zone, :cover_photo_id).presence
      return if cover_id.blank?

      @zone.cover_attachment_id = @zone.photos.ids.include?(cover_id.to_i) ? cover_id.to_i : nil
    end

    def zone_params
      params.require(:zone).permit(:building_id, :name, :description, :capacity, :floor,
                                   :hourly_rate_cents, :min_duration_minutes, :max_duration_minutes,
                                   :requires_approval, :active, :room_type, :building_code,
                                   :cleaning_buffer_minutes, amenity_ids: [], adjacent_zone_ids: [],
                                   price_rules_attributes: %i[id day_kind starts_at_time(1i) starts_at_time(2i) starts_at_time(3i) starts_at_time(4i) starts_at_time(5i) ends_at_time(1i) ends_at_time(2i) ends_at_time(3i) ends_at_time(4i) ends_at_time(5i) hourly_rate_cents _destroy])
    end

    def set_zone
      @zone = Zone.find(params[:id])
    end
  end
end
