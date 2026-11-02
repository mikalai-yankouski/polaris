require "rails_helper"

RSpec.describe "Admin", type: :request do
  describe "GET /admin" do
    it "shows analytics dashboard to an admin" do
      sign_in create(:user, :admin)

      get admin_root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Аналитика")
    end

    it "shows the dashboard to a manager" do
      sign_in create(:user, :manager)

      get admin_root_path

      expect(response).to have_http_status(:ok)
    end

    it "redirects a regular member" do
      sign_in create(:user)

      get admin_root_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /admin/reservations/:id/confirm" do
    it "confirms a pending reservation and notifies the user" do
      sign_in create(:user, :manager)
      reservation = create(:reservation)

      expect {
        post confirm_admin_reservation_path(reservation)
      }.to have_enqueued_mail(ReservationMailer, :confirmed)

      expect(reservation.reload).to be_confirmed
    end

    it "does not allow a member to confirm" do
      sign_in create(:user)
      reservation = create(:reservation)

      expect {
        post confirm_admin_reservation_path(reservation)
      }.not_to change { reservation.reload.status }

      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /admin/users/:id" do
    let(:target) { create(:user) }

    it "admin changes a role" do
      sign_in create(:user, :admin)

      patch admin_user_path(target), params: { user: { role: "manager" } }

      expect(target.reload).to be_manager
    end

    it "manager cannot change roles" do
      sign_in create(:user, :manager)

      patch admin_user_path(target), params: { user: { role: "admin" } }

      expect(target.reload).to be_member
    end
  end
end
