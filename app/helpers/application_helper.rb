module ApplicationHelper
  def money(cents)
    number_to_currency(cents.to_f / 100, unit: "BYN", format: "%n %u", precision: 2, separator: ",", delimiter: " ")
  end

  def duration_text(minutes)
    minutes = minutes.to_i
    if (minutes % 60).zero?
      t("datetime.distance_in_words.x_hours", count: minutes / 60)
    else
      "#{minutes / 60} #{t('hours_short')} #{minutes % 60} #{t('minutes_short')}"
    end
  end

  # Inline SVG-иконки (стиль Lucide: stroke 1.7, round caps) — без внешних зависимостей
  ICONS = {
    sparkle: '<path d="M12 3l1.9 5.8a2 2 0 0 0 1.3 1.3L21 12l-5.8 1.9a2 2 0 0 0-1.3 1.3L12 21l-1.9-5.8a2 2 0 0 0-1.3-1.3L3 12l5.8-1.9a2 2 0 0 0 1.3-1.3z"/>',
    users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
    building: '<path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z"/><path d="M6 12H4a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h2"/><path d="M18 9h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-2"/><path d="M10 6h4"/><path d="M10 10h4"/><path d="M10 14h4"/><path d="M10 18h4"/>',
    clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    calendar: '<rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4"/><path d="M8 2v4"/><path d="M3 10h18"/>',
    credit_card: '<rect x="2" y="5" width="20" height="14" rx="2"/><path d="M2 10h20"/>',
    check_circle: '<path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><path d="m9 11 3 3L22 4"/>',
    arrow_right: '<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>',
    arrow_down: '<path d="M12 5v14"/><path d="m19 12-7 7-7-7"/>',
    moon: '<path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"/>',
    sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2"/><path d="M12 20v2"/><path d="m4.93 4.93 1.41 1.41"/><path d="m17.66 17.66 1.41 1.41"/><path d="M2 12h2"/><path d="M20 12h2"/><path d="m6.34 17.66-1.41 1.41"/><path d="m19.07 4.93-1.41 1.41"/>',
    shield: '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1 1 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/>',
    zap: '<path d="M4 14a1 1 0 0 1-.78-1.63l9.9-10.2a.5.5 0 0 1 .86.46l-1.92 6.02A1 1 0 0 0 13 10h7a1 1 0 0 1 .78 1.63l-9.9 10.2a.5.5 0 0 1-.86-.46l1.92-6.02A1 1 0 0 0 11 14z"/>',
    # Типы комнат
    lounge: '<path d="M19 9V6a2 2 0 0 0-2-2H7a2 2 0 0 0-2 2v3"/><path d="M4 11a2 2 0 1 1 4 0v2h8v-2a2 2 0 1 1 4 0v5a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2z"/><path d="M5 20v1"/><path d="M19 20v1"/>',
    cinema: '<path d="M20.2 6 3 11l-.9-2.4c-.3-1.1.3-2.2 1.3-2.5l13.5-4c1.1-.3 2.2.3 2.5 1.3Z"/><path d="m6.2 5.3 3.1 3.9"/><path d="m12.4 3.4 3.1 4"/><path d="M3 11h18v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z"/>',
    karaoke: '<path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2"/><path d="M12 19v3"/>',
    billiard: '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="3.5"/>',
    ps5: '<line x1="6" x2="10" y1="11" y2="11"/><line x1="8" x2="8" y1="9" y2="13"/><line x1="15" x2="15.01" y1="12" y2="12"/><line x1="18" x2="18.01" y1="10" y2="10"/><path d="M17.32 5H6.68a4 4 0 0 0-3.978 3.59c-.006.052-.01.101-.017.152C2.604 9.416 2 14.456 2 16a3 3 0 0 0 3 3c1 0 1.5-.5 2-1l1.414-1.414A2 2 0 0 1 9.828 16h4.344a2 2 0 0 1 1.414.586L17 18c.5.5 1 1 2 1a3 3 0 0 0 3-3c0-1.545-.604-6.584-.685-7.258-.007-.05-.011-.1-.017-.151A4 4 0 0 0 17.32 5z"/>',
    chevron_down: '<path d="m6 9 6 6 6-6"/>',
    chevron_left: '<path d="m15 18-6-6 6-6"/>',
    chevron_right: '<path d="m9 18 6-6-6-6"/>'
  }.freeze

  def icon(name, css_class: nil)
    content_tag :svg, ICONS.fetch(name.to_sym).html_safe, # rubocop:disable Rails/OutputSafety
                xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 24 24", fill: "none",
                stroke: "currentColor", "stroke-width" => "1.7", "stroke-linecap" => "round",
                "stroke-linejoin" => "round", class: css_class, "aria-hidden" => "true"
  end

  STATUS_BADGE_CLASSES = {
    "pending"   => "badge--pending",
    "confirmed" => "badge--confirmed",
    "declined"  => "badge--declined",
    "cancelled" => "badge--cancelled",
    "completed" => "badge--completed"
  }.freeze

  def status_badge(reservation)
    content_tag :span, reservation.status_label, class: "badge #{STATUS_BADGE_CLASSES.fetch(reservation.status)}"
  end

  PAYMENT_BADGE_CLASSES = {
    "successful" => "badge--successful",
    "pending"    => "badge--pending",
    "failed"     => "badge--failed"
  }.freeze

  def payment_badge(reservation)
    return "" unless reservation.blocking?

    if reservation.paid?
      payment = reservation.payments.successful.first
      label = payment&.on_site? ? t("payments.badge.paid_on_site") : t("payments.badge.paid")
      status = "successful"
    else
      label = t("payments.badge.unpaid")
      status = "pending"
    end
    content_tag :span, label, class: "badge #{PAYMENT_BADGE_CLASSES.fetch(status)}"
  end

  def nav_link(name = nil, options = nil, &)
    classes = %w[nav-link]
    classes << "nav-link--active" if current_page?(options)
    link_to name, options, class: classes.join(" "), &
  end

  # Ссылка сайдбара админки: иконка + подпись + активное состояние
  def side_link(name, path, icon_name = nil)
    classes = %w[side-link]
    classes << "side-link--active" if current_page?(path)
    link_to path, class: classes.join(" ") do
      safe_join([ icon(icon_name), ERB::Util.html_escape(name) ])
    end
  end

  # Время начала в гостевой заявке: шаг 30 минут
  def booking_time_options
    (0...48).map { |i| format("%02d:%02d", i / 2, i.even? ? 0 : 30) }
  end

  # Длительность в гостевой заявке: от минимума до максимума зоны, шаг 30 минут
  def booking_duration_options(zone)
    (zone.min_duration_minutes..zone.max_duration_minutes).step(30).map do |minutes|
      [ duration_text(minutes), minutes ]
    end
  end

  # Длительность по умолчанию — ближе к двум часам
  def booking_duration_default(zone)
    steps = (zone.min_duration_minutes..zone.max_duration_minutes).step(30).to_a
    steps.min_by { |minutes| (minutes - 120).abs } || zone.min_duration_minutes
  end
end
