require "rails_helper"

RSpec.describe Payments::Checkout do
  let(:reservation) { create(:reservation) }
  let(:fake_client) do
    Class.new do
      attr_reader :args

      def create_checkout(**args)
        @args = args
        { "redirect_url" => "https://checkout.bepaid.by/v2/checkout?token=test" }
      end
    end.new
  end

  it "creates a pending payment and returns the bePaid redirect url" do
    result = described_class.call(
      reservation:, return_url: "https://polaris.test/reservations",
      notification_url: "https://polaris.test/bepaid/webhook", client: fake_client
    )

    expect(result).to be_success
    expect(result.redirect_url).to include("checkout.bepaid.by")
    payment = reservation.payments.last
    expect(payment).to be_pending
    expect(payment.amount_cents).to eq(reservation.total_price_cents)
    expect(payment.tracking_id).to start_with("polaris-rs-")
    expect(fake_client.args[:tracking_id]).to eq(payment.tracking_id)
    expect(fake_client.args[:amount]).to eq(reservation.total_price_cents / 100.0)
  end

  it "refuses an already paid reservation" do
    reservation.payments.create!(tracking_id: "t-1", amount_cents: 100, status: :successful, paid_at: Time.current)

    result = described_class.call(
      reservation:, return_url: "https://x.test/r", notification_url: "https://x.test/n", client: fake_client
    )

    expect(result).not_to be_success
    expect(result.message).to be_present
  end

  it "returns an error result when bePaid fails" do
    failing = Class.new do
      def create_checkout(**)
        raise Bepaid::Client::RequestError, "bePaid ответил 500"
      end
    end.new

    result = described_class.call(
      reservation:, return_url: "https://x.test/r", notification_url: "https://x.test/n", client: failing
    )

    expect(result).not_to be_success
    expect(result.message).to include("bePaid")
  end
end
