require "rails_helper"

RSpec.describe Reservation, type: :model do
  describe "validations" do
    it "is valid with factory defaults" do
      expect(build(:reservation)).to be_valid
    end

    it "computes price from zone rate and duration" do
      reservation = create(:reservation, starts_at: Time.zone.parse("2030-01-01 10:00"), ends_at: Time.zone.parse("2030-01-01 12:30"))
      # 50 BYN/час × 2.5 часа = 125 BYN = 12 500 коп.
      expect(reservation.total_price_cents).to eq(12_500)
    end

    it "rejects end before start" do
      reservation = build(:reservation, starts_at: 1.day.from_now, ends_at: 1.day.from_now - 1.hour)
      expect(reservation).not_to be_valid
      expect(reservation.errors[:ends_at]).to be_present
    end

    it "rejects start in the past" do
      reservation = build(:reservation, starts_at: 1.day.ago, ends_at: 1.day.ago + 2.hours)
      expect(reservation).not_to be_valid
      expect(reservation.errors[:starts_at]).to be_present
    end

    it "rejects duration shorter than zone minimum" do
      reservation = build(:reservation, starts_at: Time.zone.parse("2030-01-01 10:00"), ends_at: Time.zone.parse("2030-01-01 10:30"))
      expect(reservation).not_to be_valid
      expect(reservation.errors[:ends_at].join).to include("минимум")
    end

    it "rejects more guests than zone capacity" do
      reservation = build(:reservation, guests_count: 11)
      expect(reservation).not_to be_valid
      expect(reservation.errors[:guests_count]).to be_present
    end

    it "rejects booking of inactive zone" do
      zone = create(:zone, active: false)
      reservation = build(:reservation, zone:)
      expect(reservation).not_to be_valid
      expect(reservation.errors[:zone]).to be_present
    end

    describe "overlap prevention" do
      let(:zone) { create(:zone) }

      it "rejects an overlapping booking in app-level validation" do
        create(:reservation, :confirmed, zone:, starts_at: Time.zone.parse("2030-01-01 10:00"), ends_at: Time.zone.parse("2030-01-01 12:00"))
        overlapping = build(:reservation, zone:, starts_at: Time.zone.parse("2030-01-01 11:00"), ends_at: Time.zone.parse("2030-01-01 13:00"))

        expect(overlapping).not_to be_valid
        expect(overlapping.errors[:starts_at].join).to include("занято")
      end

      it "allows a cancelled booking to be rebooked" do
        create(:reservation, zone:, starts_at: Time.zone.parse("2030-01-01 10:00"), ends_at: Time.zone.parse("2030-01-01 12:00"))
            .update_column(:status, Reservation.statuses[:cancelled])

        expect(build(:reservation, zone:, starts_at: Time.zone.parse("2030-01-01 11:00"), ends_at: Time.zone.parse("2030-01-01 13:00"))).to be_valid
      end

      it "enforces no-overlap at the database level (exclusion constraint)" do
        create(:reservation, :confirmed, zone:, starts_at: Time.zone.parse("2030-01-01 10:00"), ends_at: Time.zone.parse("2030-01-01 12:00"))

        expect {
          reservation = Reservation.new(zone:, user: create(:user),
                                        starts_at: Time.zone.parse("2030-01-01 11:00"), ends_at: Time.zone.parse("2030-01-01 13:00"),
                                        guests_count: 1)
          reservation.validate
          reservation.save(validate: false)
        }.to raise_error(ActiveRecord::StatementInvalid) { |error|
          expect(error.cause).to be_a(PG::ExclusionViolation)
        }
      end

      it "enforces the cleaning buffer at the database level" do
        create(:reservation, :confirmed, zone:, starts_at: Time.zone.parse("2030-01-01 10:00"), ends_at: Time.zone.parse("2030-01-01 12:00"))

        expect {
          reservation = Reservation.new(zone:, user: create(:user),
                                        starts_at: Time.zone.parse("2030-01-01 12:05"), ends_at: Time.zone.parse("2030-01-01 14:00"),
                                        guests_count: 1)
          reservation.save(validate: false)
        }.to raise_error(ActiveRecord::StatementInvalid) { |error|
          expect(error.cause).to be_a(PG::ExclusionViolation)
        }
      end

      describe "cleaning buffer" do
        it "blocks a booking that starts inside the cleaning window" do
          create(:reservation, :confirmed, zone:, starts_at: Time.zone.parse("2030-01-01 10:00"), ends_at: Time.zone.parse("2030-01-01 12:00"))

          expect(build(:reservation, zone:, starts_at: Time.zone.parse("2030-01-01 12:00"), ends_at: Time.zone.parse("2030-01-01 14:00"))).not_to be_valid
        end

        it "allows a booking right after the cleaning window" do
          create(:reservation, :confirmed, zone:, starts_at: Time.zone.parse("2030-01-01 10:00"), ends_at: Time.zone.parse("2030-01-01 12:00"))

          expect(build(:reservation, zone:, starts_at: Time.zone.parse("2030-01-01 12:15"), ends_at: Time.zone.parse("2030-01-01 14:15"))).to be_valid
        end

        it "extends the buffer to 30 minutes for children parties" do
          create(:reservation, :confirmed, zone:, children_party: true,
                 starts_at: Time.zone.parse("2030-01-01 10:00"), ends_at: Time.zone.parse("2030-01-01 12:00"))

          too_early = build(:reservation, zone:, starts_at: Time.zone.parse("2030-01-01 12:15"), ends_at: Time.zone.parse("2030-01-01 14:15"))
          expect(too_early).not_to be_valid

          after_buffer = build(:reservation, zone:, starts_at: Time.zone.parse("2030-01-01 12:30"), ends_at: Time.zone.parse("2030-01-01 14:30"))
          expect(after_buffer).to be_valid
        end
      end

      describe "karaoke adjacency rule" do
        let(:karaoke_zone) { create(:zone, :karaoke, name: "Караоке А") }
        let(:neighbour) { create(:zone, :karaoke, name: "Караоке Б") }
        let(:far_away) { create(:zone) }

        before do
          karaoke_zone.adjacent_zones << neighbour
        end

        it "rejects a karaoke booking adjacent to a simultaneous karaoke booking" do
          create(:reservation, :confirmed, zone: neighbour,
                 starts_at: Time.zone.parse("2030-01-01 18:00"), ends_at: Time.zone.parse("2030-01-01 20:00"))

          booking = build(:reservation, zone: karaoke_zone,
                          starts_at: Time.zone.parse("2030-01-01 19:00"), ends_at: Time.zone.parse("2030-01-01 21:00"))
          expect(booking).not_to be_valid
          expect(booking.errors[:base].join).to include("караоке")
        end

        it "allows karaoke bookings in non-adjacent rooms" do
          create(:reservation, :confirmed, zone: far_away,
                 starts_at: Time.zone.parse("2030-01-01 18:00"), ends_at: Time.zone.parse("2030-01-01 20:00"))

          booking = build(:reservation, zone: karaoke_zone,
                          starts_at: Time.zone.parse("2030-01-01 19:00"), ends_at: Time.zone.parse("2030-01-01 21:00"))
          expect(booking).to be_valid
        end
      end
    end

    describe "#extend!" do
      it "extends by 30 minutes and charges for the extension at the base rate" do
        reservation = create(:reservation, starts_at: Time.zone.parse("2030-01-01 10:00"), ends_at: Time.zone.parse("2030-01-01 12:00"))
        # 2 ч × 50 BYN = 100 BYN
        expect(reservation.total_price_cents).to eq(10_000)

        reservation.extend!(30)

        expect(reservation.reload.ends_at).to eq(Time.zone.parse("2030-01-01 12:30"))
        expect(reservation.total_price_cents).to eq(12_500)
      end

      it "refuses extension into another booking" do
        reservation = create(:reservation, :confirmed, starts_at: Time.zone.parse("2030-01-01 10:00"), ends_at: Time.zone.parse("2030-01-01 12:00"))
        create(:reservation, :confirmed, zone: reservation.zone,
               starts_at: Time.zone.parse("2030-01-01 12:30"), ends_at: Time.zone.parse("2030-01-01 14:30"))

        expect { reservation.extend!(30) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "refuses extension of a cancelled booking" do
        reservation = create(:reservation)
        reservation.update_column(:status, Reservation.statuses[:cancelled])

        expect { reservation.extend!(30) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "status transitions" do
    it "auto-confirms reservations for zones without approval" do
      reservation = create(:reservation, :auto_zone)
      expect(reservation.reload).to be_confirmed
    end

    it "keeps pending status for zones requiring approval" do
      expect(create(:reservation).reload).to be_pending
    end

    it "confirms a pending reservation" do
      reservation = create(:reservation)
      reservation.confirm!
      expect(reservation.reload).to be_confirmed
    end

    it "declines with a note" do
      reservation = create(:reservation)
      reservation.decline!(note: "Занято")
      expect(reservation.reload).to be_declined
      expect(reservation.review_note).to eq("Занято")
    end

    it "cannot confirm a declined reservation" do
      reservation = create(:reservation)
      reservation.update_column(:status, Reservation.statuses[:declined])

      expect { reservation.confirm! }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "cancels a confirmed reservation" do
      reservation = create(:reservation, :confirmed)
      reservation.cancel!
      expect(reservation.reload).to be_cancelled
    end
  end
end
