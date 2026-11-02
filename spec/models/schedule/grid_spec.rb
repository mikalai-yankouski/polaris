require "rails_helper"

RSpec.describe Schedule::Grid, type: :model do
  let(:date) { 3.days.from_now.to_date }
  let(:zone) { create(:zone) }
  let(:grid) { described_class.new(date:, zones: [ zone ]) }

  def cell_at(hour)
    grid.cells_for(zone).find { |cell| cell.hour == hour }
  end

  def at(hour, day = date)
    Time.zone.local(day.year, day.month, day.day, hour)
  end

  it "marks booking hours with the reservation status" do
    create(:reservation, :confirmed, zone:,
           starts_at: at(10), ends_at: at(12))

    expect(cell_at(10).state).to eq(:confirmed)
    expect(cell_at(11).state).to eq(:confirmed)
  end

  it "marks the cleaning buffer after a booking" do
    create(:reservation, :confirmed, zone:,
           starts_at: at(10), ends_at: at(11))

    expect(cell_at(11).state).to eq(:cleaning)
  end

  it "marks pending bookings distinctly" do
    create(:reservation, zone:,
           starts_at: at(14), ends_at: at(16))

    expect(cell_at(14).state).to eq(:pending)
  end

  it "leaves free hours free" do
    create(:reservation, :confirmed, zone:,
           starts_at: at(10), ends_at: at(12))

    expect(cell_at(9).state).to eq(:free)
    expect(cell_at(13).state).to eq(:free)
  end

  it "shows booking spanning midnight from the previous day" do
    long_zone = create(:zone, max_duration_minutes: 720)
    long_grid = described_class.new(date:, zones: [ long_zone ])
    create(:reservation, :confirmed, zone: long_zone,
           starts_at: at(22, date - 1.day), ends_at: at(9)) # вчера 22:00 — сегодня 09:00

    cells = long_grid.cells_for(long_zone)
    expect(cells.find { |c| c.hour == 8 }.state).to eq(:confirmed)
    expect(cells.find { |c| c.hour == 10 }.state).to eq(:free)
  end
end
