require "rails_helper"

RSpec.describe "Reservations", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "POST /zones/:zone_id/reservations" do
    let(:zone) { create(:zone) }

    it "creates a pending reservation and enqueues notification" do
      expect {
        post zone_reservations_path(zone), params: {
          reservation: {
            starts_at: "2030-01-01T10:00", ends_at: "2030-01-01T12:00",
            guests_count: 3, purpose: "Планирование"
          }
        }
      }.to change(Reservation, :count).by(1)
                             .and have_enqueued_mail(ReservationMailer, :submitted)

      expect(Reservation.last).to be_pending
      expect(response).to redirect_to(reservations_path)
    end

    it "auto-confirms for a zone without approval" do
      zone = create(:zone, requires_approval: false)

      post zone_reservations_path(zone), params: {
        reservation: { starts_at: "2030-01-01T10:00", ends_at: "2030-01-01T12:00", guests_count: 2 }
      }

      expect(Reservation.last).to be_confirmed
    end

    it "re-renders the form when the slot is taken" do
      create(:reservation, :confirmed, zone:, starts_at: Time.zone.parse("2030-01-01 10:00"), ends_at: Time.zone.parse("2030-01-01 12:00"))

      post zone_reservations_path(zone), params: {
        reservation: { starts_at: "2030-01-01T11:00", ends_at: "2030-01-01T13:00", guests_count: 2 }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("занято")
    end
  end

  describe "POST /reservations/:id/cancel" do
    it "cancels own reservation" do
      reservation = create(:reservation, user:)

      post cancel_reservation_path(reservation)

      expect(reservation.reload).to be_cancelled
      expect(response).to redirect_to(reservations_path)
    end

    it "forbids cancelling someone else's reservation" do
      reservation = create(:reservation, user: create(:user))

      expect {
        post cancel_reservation_path(reservation)
      }.not_to change { reservation.reload.status }

      expect(response).to redirect_to(root_path)
    end
  end
end
