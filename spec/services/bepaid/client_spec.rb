require "rails_helper"

RSpec.describe Bepaid::Client do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:connection) do
    Faraday.new do |f|
      f.request :json
      f.response :json, content_type: /\bjson$/
      f.adapter :test, stubs
    end
  end
  let(:client) { described_class.new(shop_id: "shop-1", secret_key: "secret-1", connection:) }

  def checkout_stub(status:, body:)
    stubs.post("https://checkout.bepaid.by/ctp/api/checkouts") do |env|
      @request_env = env
      [ status, { "Content-Type" => "application/json" }, body.to_json ]
    end
  end

  def request_body
    JSON.parse(@request_env.request_body)
  end

  it "creates a checkout with amount in minor units and Basic auth" do
    checkout_stub(status: 200, body: { checkout: { redirect_url: "https://checkout.bepaid.by/v2/checkout?token=abc" } })

    checkout = client.create_checkout(
      amount: 125.0, tracking_id: "polaris-rs-1-abc", description: "Тест",
      return_url: "https://polaris.test/reservations", notification_url: "https://polaris.test/bepaid/webhook"
    )

    expect(checkout["redirect_url"]).to include("token=abc")
    body = request_body.dig("checkout", "order")
    expect(body["amount"]).to eq(12_500)
    expect(body["currency"]).to eq("BYN")
    expect(body["tracking_id"]).to eq("polaris-rs-1-abc")
    expect(request_body.dig("checkout", "settings", "notification_url")).to eq("https://polaris.test/bepaid/webhook")
    expect(request_body.dig("checkout", "transaction_type")).to eq("payment")
  end

  it "raises RequestError on a bePaid error response" do
    checkout_stub(status: 422, body: { message: "Invalid shop" })

    expect {
      client.create_checkout(amount: 1, tracking_id: "t", description: "d",
                             return_url: "https://x.test/r", notification_url: "https://x.test/n")
    }.to raise_error(described_class::RequestError, /422/)
  end

  it "raises ConfigurationError without credentials" do
    allow(Bepaid::Config).to receive_messages(shop_id: nil, secret_key: nil)
    expect { described_class.new }.to raise_error(described_class::ConfigurationError)
  end
end
