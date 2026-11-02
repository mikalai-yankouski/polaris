# Публичный эндпоинт: bePaid вызывает его напрямую с HTTP Basic Auth
# (shop_id/secret_key) и подписью Content-Signature. Не наследуется от
# ApplicationController — сессий и CSRF здесь быть не должно.
class BepaidWebhooksController < ActionController::Base
  skip_forgery_protection

  before_action :authenticate_bepaid!

  def create
    Payments::WebhookProcessor.call(payload: signed_payload)
    head :ok
  rescue StandardError => e
    Rails.logger.error("[payments] webhook processing failed: #{e.class}: #{e.message}")
    # 500 — bePaid повторит доставку, платёж не потеряется
    head :internal_server_error
  end

  private

    def authenticate_bepaid!
      return head(:unauthorized) unless Bepaid::Config.configured? && valid_basic_auth?

      # Ключ настроен — подпись обязательна. Без ключа пропускаем только
      # вне production (локальная проверка оплаты вручную).
      if Bepaid::Config.public_key.present?
        return if valid_signature?

        Rails.logger.error("[payments] webhook rejected: Content-Signature invalid")
        head(:forbidden)
      elsif Rails.env.production?
        Rails.logger.error("[payments] webhook rejected: no BEPAID_PUBLIC_KEY in production")
        head(:forbidden)
      end
    end

    def valid_basic_auth?
      authenticate_with_http_basic do |shop_id, secret_key|
        ActiveSupport::SecurityUtils.secure_compare(shop_id.to_s, Bepaid::Config.shop_id.to_s) &&
          ActiveSupport::SecurityUtils.secure_compare(secret_key.to_s, Bepaid::Config.secret_key.to_s)
      end
    end

    def valid_signature?
      signature = request.headers["Content-Signature"]
      return false if signature.blank?

      key = Bepaid::Config.public_key_rsa
      return false if key.nil?

      key.verify(OpenSSL::Digest.new("SHA256"), Base64.decode64(signature), request.raw_post)
    rescue OpenSSL::PKey::PKeyError, ArgumentError, TypeError
      false
    end

    # Подпись покрывает именно тело запроса, не params
    def signed_payload
      parsed = JSON.parse(request.raw_post)
      parsed.is_a?(Hash) ? parsed : {}
    rescue JSON::ParserError
      {}
    end
end
