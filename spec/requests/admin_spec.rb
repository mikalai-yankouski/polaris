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

  describe "GET /admin/schedule" do
    it "renders the occupancy grid" do
      sign_in create(:user, :manager)
      zone = create(:zone, name: "Кинокомната")
      day = 3.days.from_now
      create(:reservation, :confirmed, zone:,
             starts_at: day.change(hour: 12, min: 0), ends_at: day.change(hour: 14, min: 0))

      get admin_schedule_path(date: day.to_date)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Кинокомната")
    end
  end

  describe "POST /admin/reservations/:id/extend" do
    it "extends a booking by 30 minutes" do
      sign_in create(:user, :manager)
      reservation = create(:reservation, :confirmed)

      expect {
        post extend_admin_reservation_path(reservation, minutes: 30)
      }.to change { reservation.reload.ends_at }

      expect(reservation.ends_at).to eq(reservation.starts_at + 2.5.hours)
      expect(response).to redirect_to(admin_reservations_path)
    end

    it "refuses extension into a conflict" do
      sign_in create(:user, :manager)
      reservation = create(:reservation, :confirmed)
      create(:reservation, :confirmed, zone: reservation.zone,
             starts_at: reservation.ends_at + 15.minutes, ends_at: reservation.ends_at + 3.hours)

      post extend_admin_reservation_path(reservation, minutes: 30)

      expect(response).to redirect_to(admin_reservations_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "POST /admin/reservations/:id/record_on_site" do
    it "records a successful on-site payment" do
      sign_in create(:user, :manager)
      reservation = create(:reservation, :confirmed)

      expect {
        post record_on_site_admin_reservation_path(reservation)
      }.to change { reservation.payments.count }

      expect(reservation.reload).to be_paid
      expect(reservation.payments.last).to be_on_site
    end
  end

  describe "GET /admin/reports/room_hours" do
    it "renders the html report" do
      sign_in create(:user, :admin)

      get admin_room_hours_report_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Занятые часы")
    end

    it "exports xlsx" do
      sign_in create(:user, :admin)
      zone = create(:zone)
      create(:reservation, :confirmed, zone:,
             starts_at: Time.zone.parse("2030-01-01 10:00"), ends_at: Time.zone.parse("2030-01-01 13:00"))

      get admin_room_hours_report_path(format: :xlsx, from: "2029-12-31", to: "2030-01-02")

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("spreadsheetml")
      expect(response.body.byteslice(0, 2)).to eq("PK") # zip-магия xlsx
    end
  end
end
