require "rails_helper"

RSpec.describe "Bepaid webhooks", type: :request do
  let(:reservation) { create(:reservation) }
  let(:payment) do
    reservation.payments.create!(
      tracking_id: "polaris-rs-wh-1", amount_cents: reservation.total_price_cents,
      currency: "BYN", test: true
    )
  end

  let(:payload) do
    {
      transaction: {
        uid: "uid-1", status: "successful", amount: reservation.total_price_cents,
        currency: "BYN", test: true, tracking_id: "polaris-rs-wh-1"
      }
    }.to_json
  end

  around do |example|
    keys = %w[BEPAID_SHOP_ID BEPAID_SECRET_KEY BEPAID_PUBLIC_KEY]
    old = keys.to_h { |k| [ k, ENV[k] ] }
    ENV["BEPAID_SHOP_ID"] = "shop-test"
    ENV["BEPAID_SECRET_KEY"] = "secret-test"
    ENV["BEPAID_PUBLIC_KEY"] = ""
    begin
      example.run
    ensure
      old.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    end
  end

  it "processes a signed-in (basic auth) notification" do
    payment

    post bepaid_webhook_path, params: payload,
                              headers: { "CONTENT_TYPE" => "application/json",
                                         "AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("shop-test", "secret-test") }

    expect(response).to have_http_status(:ok)
    expect(payment.reload).to be_successful
  end

  it "rejects wrong credentials" do
    post bepaid_webhook_path, params: payload,
                              headers: { "CONTENT_TYPE" => "application/json",
                                         "AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("bad", "creds") }

    expect(response).to have_http_status(:unauthorized)
  end
end
