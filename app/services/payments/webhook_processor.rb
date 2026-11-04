module Payments
  # Применяет уведомление bePaid к платежу. Ключ связи — tracking_id: запись
  # Payment создаётся до запроса чекаута, поэтому обновляется только уже
  # существующий платёж; неизвестные tracking_id игнорируются (чужие или
  # повторные уведомления). Идемпотентно: успешный платёж не переоткрывается.
  class WebhookProcessor
    FAILED_STATUSES = %w[failed expired declined error].freeze

    def self.call(payload:)
      new(payload:).call
    end

    def initialize(payload:)
      transaction = payload.to_h.with_indifferent_access[:transaction]
      @transaction = transaction.is_a?(Hash) ? transaction.with_indifferent_access : {}
    end

    def call
      return if @transaction[:tracking_id].blank?

      payment = Payment.find_by(tracking_id: @transaction[:tracking_id].to_s)
      return unless payment

      # bePaid может доставить одно уведомление дважды и даже параллельно
      payment.with_lock do
        next if payment.status == "successful"

        apply(payment)
      end
    end

    private

    def apply(payment)
      status = @transaction[:status].presence || "unknown"

      if status == "successful" && !valid_success?(payment)
        Rails.logger.error("[payments] webhook rejected: status=successful but checks failed payment=#{payment.id}")
        record(payment, "failed")
        return
      end

      record(payment, status)

      if status == "successful"
        payment.update!(paid_at: Time.current)
        ReservationMailer.deliver_if_user(payment.reservation, :paid)
      end
    end

    # Сумма, валюта и тестовый флаг должны совпадать с созданным платежом:
    # тестовая карта не должна закрывать реальную бронь, и наоборот.
    def valid_success?(payment)
      amount_matches?(payment) && test_flag_matches?(payment)
    end

    def amount_matches?(payment)
      payment.amount_cents == @transaction[:amount].to_i &&
        payment.currency == @transaction[:currency].to_s.upcase
    end

    def test_flag_matches?(payment)
      ActiveModel::Type::Boolean.new.cast(@transaction[:test]) == payment.test?
    end

    def record(payment, status)
      mapped = FAILED_STATUSES.include?(status) ? "failed" : Payment.statuses.key?(status) ? status : "pending"
      payment.update!(
        status: mapped,
        bepaid_uid: @transaction[:uid],
        raw_response: @transaction.to_h
      )
    end
  end
end
