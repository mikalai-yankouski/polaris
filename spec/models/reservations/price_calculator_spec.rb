require "rails_helper"

RSpec.describe Reservations::PriceCalculator, type: :model do
  let(:zone) { create(:zone, hourly_rate_cents: 10_000) }

  before do
    # будни: день 10–17 — 30 BYN/ч, вечер 17–23 — 50 BYN/ч
    create(:price_rule, zone:, day_kind: :weekday, starts_at_time: "10:00", ends_at_time: "17:00", hourly_rate_cents: 3000)
    create(:price_rule, zone:, day_kind: :weekday, starts_at_time: "17:00", ends_at_time: "23:00", hourly_rate_cents: 5000)
    # выходные: день — 40 BYN/ч, вечер — 60 BYN/ч
    create(:price_rule, zone:, day_kind: :weekend, starts_at_time: "10:00", ends_at_time: "17:00", hourly_rate_cents: 4000)
    create(:price_rule, zone:, day_kind: :weekend, starts_at_time: "17:00", ends_at_time: "23:00", hourly_rate_cents: 6000)
  end

  def monday(hour)
    monday = 1.week.from_now.beginning_of_week(:monday).change(hour:, min: 0)
    expect(monday).to be_monday
    monday
  end

  def saturday(hour)
    saturday = 1.week.from_now.beginning_of_week(:monday) + 5.days
    saturday.change(hour:, min: 0).tap { |t| expect(t).to be_saturday }
  end

  subject(:calculator) { described_class.new(zone:) }

  it "prices a weekday daytime booking with the day rate" do
    expect(calculator.total_cents(monday(10), monday(12))).to eq(6000)
  end

  it "splits a booking across day and evening windows" do
    expect(calculator.total_cents(monday(16), monday(18))).to eq(3000 + 5000)
  end

  it "uses weekend rates on Saturday" do
    expect(calculator.total_cents(saturday(10), saturday(12))).to eq(8000)
  end

  it "falls back to the base rate outside tariff windows" do
    expect(calculator.total_cents(monday(8), monday(10))).to eq(20_000)
  end

  it "rounds partial minutes up" do
    expect(calculator.total_cents(monday(10), monday(11) + 20.minutes)).to eq(3000 + 1000)
  end

  context "with a window wrapping midnight" do
    let(:night_zone) { create(:zone, hourly_rate_cents: 9999) }

    before do
      create(:price_rule, zone: night_zone, day_kind: :weekday, starts_at_time: "22:00", ends_at_time: "06:00", hourly_rate_cents: 2000)
    end

    it "prices the night part with the night rate and morning with the base rate" do
      start_time = monday(23)
      end_time = monday(23) + 3.hours # 23:00–02:00, целиком в ночном окне
      expect(described_class.new(zone: night_zone).total_cents(start_time, end_time)).to eq(6000)
    end
  end
end
