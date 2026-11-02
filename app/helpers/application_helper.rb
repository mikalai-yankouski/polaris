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

  STATUS_BADGE_CLASSES = {
    "pending"   => "bg-amber-100 text-amber-800",
    "confirmed" => "bg-emerald-100 text-emerald-800",
    "declined"  => "bg-rose-100 text-rose-800",
    "cancelled" => "bg-gray-100 text-gray-600",
    "completed" => "bg-sky-100 text-sky-800"
  }.freeze

  def status_badge(reservation)
    content_tag :span, reservation.status_label,
                class: "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium #{STATUS_BADGE_CLASSES.fetch(reservation.status)}"
  end

  PAYMENT_BADGE_CLASSES = {
    "successful" => "bg-emerald-100 text-emerald-800",
    "pending"    => "bg-amber-100 text-amber-800",
    "failed"     => "bg-rose-100 text-rose-800"
  }.freeze

  def payment_badge(reservation)
    return "" unless reservation.blocking?

    if reservation.paid?
      payment = reservation.payments.successful.first
      label = payment&.on_site? ? t("payments.badge.paid_on_site") : t("payments.badge.paid")
      classes = PAYMENT_BADGE_CLASSES.fetch("successful")
    else
      label = t("payments.badge.unpaid")
      classes = PAYMENT_BADGE_CLASSES.fetch("pending")
    end
    content_tag :span, label, class: "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium #{classes}"
  end

  def nav_link(name = nil, options = nil, &)
    classes = %w[text-slate-600 hover:text-slate-900 font-medium]
    classes << "text-slate-900 border-b-2 border-slate-900" if current_page?(options)
    link_to name, options, class: classes.join(" "), &
  end
end
