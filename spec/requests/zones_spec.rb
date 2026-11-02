require "rails_helper"

RSpec.describe "Zones", type: :request do
  describe "GET /" do
    it "lists active zones" do
      create(:zone, name: "Панорама")
      create(:zone, name: "Скрытая", active: false)

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Панорама")
      expect(response.body).not_to include("Скрытая")
    end
  end

  describe "GET /zones/:id" do
    it "shows zone details and upcoming busy slots" do
      zone = create(:zone)
      create(:reservation, :confirmed, zone:)

      get zone_path(zone)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(zone.name)
    end
  end
end
