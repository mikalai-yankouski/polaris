# Настройки магазина bePaid. Источники (в порядке приоритета): ENV, затем
# Rails credentials (`bin/rails credentials:edit`):
#
#   bepaid:
#     shop_id: "..."
#     secret_key: "..."
#     public_key: "..."
#
# BEPAID_SHOP_ID / BEPAID_SECRET_KEY / BEPAID_PUBLIC_KEY — Магазины →
# [магазин] → Подробнее → Ключи магазина в личном кабинете bePaid.
# BEPAID_TEST_MODE=true — все чекауты и платежи тестовые (тест-карты,
# реальные деньги не списываются). По умолчанию тестовый режим включён
# везде, кроме production.
module Bepaid
  module Config
    module_function

    def shop_id
      ENV["BEPAID_SHOP_ID"].presence || Rails.application.credentials.dig(:bepaid, :shop_id).presence
    end

    def secret_key
      ENV["BEPAID_SECRET_KEY"].presence || Rails.application.credentials.dig(:bepaid, :secret_key).presence
    end

    def public_key
      ENV["BEPAID_PUBLIC_KEY"].presence || Rails.application.credentials.dig(:bepaid, :public_key).presence
    end

    def configured?
      shop_id.present? && secret_key.present?
    end

    # Тестовый режим: тестовые карты, деньги не списываются
    def test_mode?
      raw = ENV["BEPAID_TEST_MODE"]
      return !Rails.env.production? if raw.blank?

      ActiveModel::Type::Boolean.new.cast(raw)
    end

    # Открытый ключ для проверки подписи webhook (Content-Signature).
    # Личный кабинет отдаёт его как base64 (DER); PEM тоже подойдёт.
    def public_key_rsa
      raw = public_key
      return nil if raw.blank?

      raw = raw.gsub('\n', "\n")
      OpenSSL::PKey::RSA.new(raw.include?("BEGIN") ? raw : Base64.decode64(raw))
    rescue OpenSSL::PKey::PKeyError, ArgumentError
      nil
    end
  end
end
