require "rails_helper"

RSpec.describe PriceRule, type: :model do
  let(:zone) { create(:zone) }

  it "rejects overlapping windows for the same day kind" do
    create(:price_rule, zone:, day_kind: :weekday, starts_at_time: "10:00", ends_at_time: "17:00", hourly_rate_cents: 3000)
    overlapping = build(:price_rule, zone:, day_kind: :weekday, starts_at_time: "16:00", ends_at_time: "23:00", hourly_rate_cents: 5000)

    expect(overlapping).not_to be_valid
    expect(overlapping.errors[:starts_at_time]).to be_present
  end

  it "allows same window for weekday and weekend" do
    create(:price_rule, zone:, day_kind: :weekday, starts_at_time: "10:00", ends_at_time: "17:00", hourly_rate_cents: 3000)
    expect(build(:price_rule, zone:, day_kind: :weekend, starts_at_time: "10:00", ends_at_time: "17:00", hourly_rate_cents: 4000)).to be_valid
  end

  it "rejects midnight-wrapping window overlapping an early morning window" do
    create(:price_rule, zone:, day_kind: :weekday, starts_at_time: "22:00", ends_at_time: "06:00", hourly_rate_cents: 2000)
    overlapping = build(:price_rule, zone:, day_kind: :weekday, starts_at_time: "05:00", ends_at_time: "10:00", hourly_rate_cents: 3000)

    expect(overlapping).not_to be_valid
  end

  it "rejects an empty window" do
    rule = build(:price_rule, zone:, starts_at_time: "10:00", ends_at_time: "10:00")
    expect(rule).not_to be_valid
  end
end
