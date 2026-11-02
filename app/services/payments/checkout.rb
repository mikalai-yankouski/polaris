module Payments
  # Создаёт предоплату брони через bePaid: сначала запись Payment с уникальным
  # tracking_id, затем чекаут; гость уходит на redirect_url (страница bePaid).
  class Checkout
    Result = Struct.new(:ok, :redirect_url, :message, keyword_init: true) do
      def success? = ok
    end

    def self.call(reservation:, return_url:, notification_url:, client: nil)
      new(reservation:, return_url:, notification_url:, client:).call
    end

    def initialize(reservation:, return_url:, notification_url:, client:)
      @reservation = reservation
      @return_url = return_url
      @notification_url = notification_url
      @client = client || default_client
    end

    def call
      return Result.new(ok: false, message: I18n.t("payments.checkout.not_payable")) unless @reservation.payable?
      return Result.new(ok: false, message: I18n.t("payments.checkout.not_configured")) unless @client

      payment = Payment.create!(
        reservation: @reservation,
        tracking_id: "polaris-rs-#{@reservation.id}-#{SecureRandom.hex(6)}",
        amount_cents: @reservation.total_price_cents,
        currency: "BYN",
        test: Bepaid::Config.test_mode?
      )

      checkout = @client.create_checkout(
        amount: @reservation.total_price_cents / 100.0,
        tracking_id: payment.tracking_id,
        description: I18n.t("payments.checkout.description", zone: @reservation.zone),
        return_url: @return_url,
        notification_url: @notification_url
      )

      Result.new(ok: true, redirect_url: checkout["redirect_url"])
    rescue Bepaid::Client::ConfigurationError
      Result.new(ok: false, message: I18n.t("payments.checkout.not_configured"))
    rescue Bepaid::Client::Error => e
      Result.new(ok: false, message: e.message)
    end

    private

    def default_client
      Bepaid::Client.new if Bepaid::Config.configured?
    end
  end
end
