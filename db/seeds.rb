# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding Polaris…"

building = Building.find_or_create_by!(name: "Polaris House") do |b|
  b.address = "Минск, пр. Независимости 1"
  b.description = "Частное здание с лаундж-зонами для встреч, работы и отдыха."
end

amenities = {
  "Проектор" => nil,
  "Видеоконференция" => nil,
  "Кофемашина" => nil,
  "Панорамные окна" => nil,
  "Библиотека" => nil,
  "Переговорный стол" => nil,
  "Софа-зона" => nil,
  "Терраса" => nil
}.keys.index_with { |name| Amenity.find_or_create_by!(name:) }

puts "  amenities: #{amenities.size}"

User.find_or_create_by!(email_address: "admin@polaris.test") do |u|
  u.name = "Админ Polaris"
  u.password = "password123"
  u.role = :admin
end
manager = User.find_or_create_by!(email_address: "manager@polaris.test") do |u|
  u.name = "Мария Менеджер"
  u.phone = "+375 29 111-22-33"
  u.password = "password123"
  u.role = :manager
end
members = %w[
  anna@polaris.test
  boris@polaris.test
  vera@polaris.test
  gleb@polaris.test
].map do |email|
  User.find_or_create_by!(email_address: email) do |u|
    u.name = email.split("@").first.capitalize
    u.password = "password123"
  end
end
puts "  users: #{User.count}"

zones_data = [
  { name: "Панорама", capacity: 12, floor: 7, hourly_rate_cents: 6000, requires_approval: true,
    description: "Просторная зона на последнем этаже с панорамными окнами и видом на город.",
    amenities: [ "Панорамные окна", "Переговорный стол", "Кофемашина", "Видеоконференция" ] },
  { name: "Библиотека", capacity: 6, floor: 3, hourly_rate_cents: 3500, requires_approval: true,
    description: "Тихая зона с книжными стеллажами и мягкими креслами для работы и чтения.",
    amenities: [ "Библиотека", "Кофемашина", "Софа-зона" ] },
  { name: "Студия", capacity: 4, floor: 2, hourly_rate_cents: 2500, requires_approval: false,
    description: "Компактная переговорная с проектором. Бронь подтверждается автоматически.",
    amenities: [ "Проектор", "Переговорный стол" ] },
  { name: "Терраса", capacity: 20, floor: 8, hourly_rate_cents: 9000, requires_approval: true,
    description: "Открытая терраса для вечерних встреч и мероприятий на свежем воздухе.",
    amenities: [ "Терраса", "Кофемашина", "Софа-зона" ] },
  { name: "Лаундж", capacity: 10, floor: 5, hourly_rate_cents: 4500, requires_approval: true,
    description: "Уютная зона отдыха с диванами и мягким светом для неформальных встреч.",
    amenities: [ "Софа-зона", "Кофемашина", "Панорамные окна" ] }
]

zones = zones_data.map do |attrs|
  amenities_names = attrs.delete(:amenities)
  zone = Zone.find_or_create_by!(name: attrs[:name]) do |z|
    z.building = building
    z.assign_attributes(attrs)
  end
  amenities_names.each do |name|
    zone.zone_amenities.find_or_create_by!(amenity: amenities.fetch(name))
  end
  zone
end
puts "  zones: #{Zone.count}"

# Демо-брони за последние 30 дней и на будущее — чтобы оживить дашборд
random = Random.new(42)
reservations_created = 0

if Reservation.count.zero?
  40.times do |i|
    zone = zones[random.rand(zones.size)]
    day = (i % 30).days.ago.beginning_of_day + random.rand(8..20).hours + [ 0, 30 ].sample.minutes
    duration = [ 60, 90, 120, 180 ].sample
    starts_at = day
    ends_at = day + duration.minutes

    # избегаем пересечений внутри сидов: пропускаем, если слот занят
    next if zone.blocked?(starts_at..ends_at)

    user = (members + [ manager ]).sample(random:)
    status = case random.rand(10)
    when 0..6 then :confirmed
    when 7 then :pending
    when 8 then :cancelled
    else :declined
    end

    # Исторические демо-брони: валидация «только будущее» не для сидов,
    # пересечения всё равно исключены проверкой выше и constraint в БД.
    reservation = Reservation.new(
      zone:, user:,
      starts_at:, ends_at:,
      guests_count: 1 + random.rand(zone.capacity),
      purpose: [ "Встреча с клиентом", "Рабочая сессия", "День рождения", "Мастер-класс", "Пленарное собрание" ].sample(random:)
    )
    reservation.total_price_cents = (zone.hourly_rate_cents * reservation.duration_minutes / 60.0).round
    reservation.save(validate: false)
    reservation.update_column(:status, Reservation.statuses[status]) unless status == :pending
    reservations_created += 1
  end

  # пара будущих броней для «Предстоящих»
  3.times do |i|
    zone = zones[i % zones.size]
    starts_at = (i + 1).days.from_now.change(hour: 10 + i, min: 0)
    next if zone.blocked?(starts_at..(starts_at + 2.hours))

    Reservation.create!(
      zone:, user: members[i],
      starts_at:, ends_at: starts_at + 2.hours,
      guests_count: 3,
      purpose: "Плановая встреча"
    )
  end
end

puts "  reservations: #{Reservation.count} (+#{reservations_created} demo)"
puts "Seeds done. Admin: admin@polaris.test / password123"
