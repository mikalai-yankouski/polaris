require "rails_helper"

RSpec.describe Payments::WebhookProcessor do
  let(:reservation) { create(:reservation) }
  let!(:payment) do
    reservation.payments.create!(
      tracking_id: "polaris-rs-1-test", amount_cents: reservation.total_price_cents,
      currency: "BYN", test: true
    )
  end

  def notification(overrides = {})
    {
      transaction: {
        uid: "111-222-333",
        status: "successful",
        amount: reservation.total_price_cents,
        currency: "BYN",
        test: true,
        tracking_id: "polaris-rs-1-test",
        message: "Successfully processed"
      }.merge(overrides)
    }
  end

  it "marks the payment successful and notifies the guest" do
    expect {
      described_class.call(payload: notification)
    }.to have_enqueued_mail(ReservationMailer, :paid)

    payment.reload
    expect(payment).to be_successful
    expect(payment.bepaid_uid).to eq("111-222-333")
    expect(payment.paid_at).to be_present
    expect(reservation.reload).to be_paid
  end

  it "is idempotent for a repeated notification" do
    expect {
      2.times { described_class.call(payload: notification) }
    }.to have_enqueued_mail(ReservationMailer, :paid).exactly(:once)

    expect(payment.reload).to be_successful
  end

  it "rejects a successful notification with a wrong amount" do
    described_class.call(payload: notification(amount: 1))

    expect(payment.reload).not_to be_successful
    expect(reservation.reload).not_to be_paid
  end

  it "maps declined to failed" do
    described_class.call(payload: notification(status: "declined", message: "Insufficient funds"))

    expect(payment.reload).to be_failed
    expect(reservation.reload).not_to be_paid
  end

  it "ignores unknown tracking ids" do
    expect {
      described_class.call(payload: notification(tracking_id: "someone-else"))
    }.not_to change(Payment, :count)
  end
end
