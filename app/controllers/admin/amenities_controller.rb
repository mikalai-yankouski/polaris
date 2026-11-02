module Admin
  class AmenitiesController < BaseController
    before_action :set_amenity, only: %i[edit update destroy]

    def index
      @amenities = policy_scope(Amenity)
      @amenity = Amenity.new
    end

    def create
      @amenity = Amenity.new(amenity_params)
      authorize @amenity
      if @amenity.save
        redirect_to admin_amenities_path, notice: t(".created")
      else
        @amenities = policy_scope(Amenity)
        render :index, status: :unprocessable_entity
      end
    end

    def edit
      authorize @amenity
    end

    def update
      authorize @amenity
      if @amenity.update(amenity_params)
        redirect_to admin_amenities_path, notice: t(".updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @amenity
      @amenity.destroy
      redirect_to admin_amenities_path, notice: t(".destroyed")
    rescue ActiveRecord::InvalidForeignKey
      redirect_to admin_amenities_path, alert: t(".in_use")
    end

    private

    def amenity_params
      params.require(:amenity).permit(:name)
    end

    def set_amenity
      @amenity = Amenity.find(params[:id])
    end
  end
end
