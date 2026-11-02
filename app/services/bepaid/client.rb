module Bepaid
  # Тонкий клиент Checkout API bePaid (по образцу интеграции в varka).
  # Единственный нужный Polaris вызов — create_checkout: страница оплаты,
  # на которую уходит гость. Номер карты мы не видим никогда.
  #
  # Документация: https://docs.bepaid.by/ru/integration/checkout/basics/
  class Client
    class Error < StandardError; end
    class ConfigurationError < Error; end
    class RequestError < Error; end
    # Ответа нет — запрос мог и пройти, и не пройти
    class NetworkError < RequestError; end

    CHECKOUT_HOST = "https://checkout.bepaid.by"
    API_VERSION = "2"

    def initialize(shop_id: nil, secret_key: nil, connection: nil)
      @shop_id = shop_id.presence || Config.shop_id
      @secret_key = secret_key.presence || Config.secret_key
      raise ConfigurationError, "bePaid не настроен (BEPAID_SHOP_ID / BEPAID_SECRET_KEY)" unless @shop_id.present? && @secret_key.present?

      @connection = connection || build_connection
    end

    # amount — сумма в BYN; здесь переводится в копейки
    def create_checkout(amount:, tracking_id:, description:, return_url:, notification_url:,
                        currency: "BYN", test: Config.test_mode?, language: "ru")
      body = {
        checkout: {
          test: test,
          transaction_type: "payment",
          settings: {
            return_url: return_url,
            notification_url: notification_url,
            language: language
          },
          order: {
            currency: currency,
            amount: minor_units(amount),
            description: description,
            tracking_id: tracking_id
          }
        }
      }
      post("#{CHECKOUT_HOST}/ctp/api/checkouts", body).fetch("checkout", {})
    end

    private

    def minor_units(amount)
      (amount.to_d * 100).round.to_i
    end

    def build_connection
      Faraday.new do |f|
        f.request :authorization, :basic, @shop_id, @secret_key
        f.request :json
        f.response :json, content_type: /\bjson$/
        f.headers["X-API-Version"] = API_VERSION
        f.headers["Accept"] = "application/json"
        f.adapter Faraday.default_adapter
        f.options.timeout = 20
        f.options.open_timeout = 10
      end
    end

    def post(url, body)
      response = @connection.post(url) { |request| request.body = body }
      handle_response(response)
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Faraday::SSLError => e
      raise NetworkError, "bePaid недоступен: #{e.message}"
    end

    def handle_response(response)
      body = parsed_body(response)
      return body if response.success?

      message = body.is_a?(Hash) ? body["message"] : nil
      raise RequestError, "bePaid ответил #{response.status}#{message.present? ? ": #{message}" : ''}"
    end

    def parsed_body(response)
      raw = response.body
      return raw if raw.is_a?(Hash)
      return {} if raw.blank?

      JSON.parse(raw.to_s)
    rescue JSON::ParserError
      {}
    end
  end
end
