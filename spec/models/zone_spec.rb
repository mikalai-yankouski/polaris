require "rails_helper"

RSpec.describe Zone, type: :model do
  describe "validations" do
    subject(:zone) { build(:zone) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.to validate_numericality_of(:capacity).is_greater_than(0).only_integer }

    it "rejects max duration below min duration" do
      zone = build(:zone, min_duration_minutes: 120, max_duration_minutes: 60)
      expect(zone).not_to be_valid
      expect(zone.errors[:max_duration_minutes]).to be_present
    end
  end

  describe "#blocked?" do
    let(:zone) { create(:zone) }

    it "is true when a confirmed reservation intersects the range" do
      create(:reservation, :confirmed, zone:, starts_at: Time.zone.parse("2030-01-01 10:00"), ends_at: Time.zone.parse("2030-01-01 12:00"))
      expect(zone.blocked?(Time.zone.parse("2030-01-01 11:00")..Time.zone.parse("2030-01-01 13:00"))).to be(true)
    end

    it "is false for a free range" do
      expect(zone.blocked?(Time.zone.parse("2030-01-01 11:00")..Time.zone.parse("2030-01-01 13:00"))).to be(false)
    end
  end
end
