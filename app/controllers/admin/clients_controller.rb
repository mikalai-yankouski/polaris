module Admin
  # Клиент — гость, оставивший телефон при бронировании (аккаунтов у клиентов нет).
  # Один и тот же человек может вводить телефон в разном формате, поэтому
  # группируем по цифрам номера, а показываем последние введённые имя и телефон.
  class ClientsController < BaseController
    def index
      authorize :client
      # Заявка может прийти без времени (слот согласуется по телефону) — тогда
      # дату берём из requested_date: у клиента всегда есть первая и последняя дата
      @clients = Reservation.where.not(guest_phone: [ nil, "" ])
                            .group("regexp_replace(guest_phone, '\\D', '', 'g')")
                            .select(
                              "(ARRAY_REMOVE(ARRAY_AGG(guest_phone ORDER BY created_at DESC), NULL))[1] AS phone",
                              "(ARRAY_REMOVE(ARRAY_AGG(NULLIF(guest_name, '') ORDER BY created_at DESC), NULL))[1] AS name",
                              "COUNT(*) AS reservations_count",
                              "MIN(COALESCE(starts_at, requested_date)) AS first_booked_at",
                              "MAX(COALESCE(starts_at, requested_date)) AS last_booked_at"
                            )
                            .order(Arel.sql("MAX(COALESCE(starts_at, requested_date)) DESC"))
    end
  end
end
