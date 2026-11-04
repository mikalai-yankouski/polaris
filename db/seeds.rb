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

# 7 комнат клуба «Дом на Полярной» (пакет решений 02.11.2026):
# второй этаж — к Новому году, первый — к февралю.
# tariffs: [день 10–17, вечер 17–23] × [будни, выходные], коп. за час
zones_data = [
  { name: "Кинокомната Большая", building_code: "2-10", room_type: :cinema, capacity: 8, floor: 2,
    base: 5000, day: [ 3500, 5000 ], evening: [ 5000, 6500 ], buffer: 15,
    description: "Большая кинокомната с ТВ 85″, диванами и попкорном.",
    amenities: [ "Проектор", "Софа-зона", "Кофемашина" ] },
  { name: "Кинокомната Малая", building_code: "2-11", room_type: :cinema, capacity: 4, floor: 2,
    base: 4000, day: [ 3000, 4000 ], evening: [ 4000, 5000 ], buffer: 15,
    description: "Уютная кинокомната на двоих-четверых.",
    amenities: [ "Проектор", "Софа-зона" ] },
  { name: "Караоке-холл", building_code: "2-8", room_type: :karaoke, capacity: 12, floor: 2,
    base: 7000, day: [ 5000, 7000 ], evening: [ 7000, 9000 ], buffer: 30,
    description: "Караоке-зал с проектором, радиомикрофонами и акустикой Denon.",
    amenities: [ "Проектор", "Кофемашина", "Софа-зона" ] },
  { name: "Лаундж 2-1", building_code: "2-1", room_type: :lounge, capacity: 10, floor: 2,
    base: 4000, day: [ 2500, 3500 ], evening: [ 4000, 5500 ], buffer: 15,
    description: "Лаундж для встреч и настольных игр.",
    amenities: [ "Софа-зона", "Кофемашина" ] },
  { name: "Бильярдная", building_code: "1-8", room_type: :billiard, capacity: 8, floor: 1,
    base: 4500, day: [ 3500, 4500 ], evening: [ 4500, 6000 ], buffer: 15,
    description: "Бильярдный стол в профессиональной зоне 1,6 м вокруг.",
    amenities: [ "Переговорный стол" ] },
  { name: "PlayStation", building_code: "1-6", room_type: :ps5, capacity: 4, floor: 1,
    base: 3000, day: [ 2000, 3000 ], evening: [ 3000, 4000 ], buffer: 15,
    description: "Комната с PS5 и ТВ: турниры по файтингам и футболу.",
    amenities: [ "Проектор" ] },
  { name: "Кинокомната Премиум", building_code: "1-4", room_type: :cinema, capacity: 6, floor: 1,
    base: 5500, day: [ 4000, 5500 ], evening: [ 5500, 7000 ], buffer: 15,
    description: "Кинокомната первого этажа с проектором и шторами.",
    amenities: [ "Проектор", "Софа-зона", "Кофемашина" ] }
]

zones = zones_data.map do |attrs|
  amenities_names = attrs.delete(:amenities)
  room_attrs = attrs.slice(:name, :building_code, :room_type, :capacity, :floor, :description)
  zone = Zone.find_or_create_by!(name: room_attrs[:name]) do |z|
    z.building = building
    z.assign_attributes(room_attrs)
    z.hourly_rate_cents = attrs[:base]
    z.min_duration_minutes = 120 # минимум 2–3 часа по ТЗ
    z.max_duration_minutes = 480
    z.requires_approval = true
    z.active = true
    z.cleaning_buffer_minutes = attrs[:buffer]
  end

  # тарифная сетка: будни/выходные × день(10–17)/вечер(17–23)
  [ [ :weekday, 0 ], [ :weekend, 1 ] ].each do |(kind, idx)|
    { "10:00" => attrs[:day][idx], "17:00" => attrs[:evening][idx] }.each do |(from, rate)|
      to = from == "10:00" ? "17:00" : "23:00"
      zone.price_rules.find_or_create_by!(day_kind: kind, starts_at_time: from, ends_at_time: to) do |rule|
        rule.hourly_rate_cents = rate
      end
    end
  end

  amenities_names.each do |name|
    zone.zone_amenities.find_or_create_by!(amenity: amenities.fetch(name))
  end
  zone
end

# смежность комнат (правило «караоке не в соседних»): соседние номера на этаже
adjacency_pairs = [ [ "2-8", "2-10" ], [ "2-10", "2-11" ], [ "2-11", "2-1" ], [ "1-4", "1-6" ] ]
by_code = zones.index_by(&:building_code)
adjacency_pairs.each do |(a_code, b_code)|
  a = by_code[a_code]
  b = by_code[b_code]
  next unless a && b

  ZoneAdjacency.find_or_create_by!(zone: a, adjacent_zone: b)
  ZoneAdjacency.find_or_create_by!(zone: b, adjacent_zone: a)
end

# Фото залов (Pexels): привязываем один раз; сет недоступен — сид не падает
zone_photos = {
  "Кинокомната Большая" => "https://image-search-mcp-cn-beijing.oss-cn-beijing.aliyuncs.com/image-search-mcp/images-ppt/d170a7f28cf4.jpg",
  "Кинокомната Малая"   => "https://image-search-mcp-cn-beijing.oss-cn-beijing.aliyuncs.com/image-search-mcp/images-ppt/5ea4d8449d1e.jpg",
  "Караоке-холл"        => "https://image-search-mcp-cn-beijing.oss-cn-beijing.aliyuncs.com/image-search-mcp/images-ppt/3898314f0aa0.jpg",
  "Лаундж 2-1"          => "https://image-search-mcp-cn-beijing.oss-cn-beijing.aliyuncs.com/image-search-mcp/images-ppt/4277c2b4a865.jpg",
  "Бильярдная"          => "https://image-search-mcp-cn-beijing.oss-cn-beijing.aliyuncs.com/image-search-mcp/images-ppt/e7b3869dc9ae.jpg",
  "PlayStation"         => "https://image-search-mcp-cn-beijing.oss-cn-beijing.aliyuncs.com/image-search-mcp/images-ppt/a3f997923c91.png",
  "Кинокомната Премиум" => "https://image-search-mcp-cn-beijing.oss-cn-beijing.aliyuncs.com/image-search-mcp/images-ppt/af55666aecac.jpg"
}
zone_photos.each do |name_part, url|
  zone = Zone.find_by("name LIKE ?", "%#{name_part}%")
  next unless zone && zone.photos.none?

  zone.photos.attach(io: URI.parse(url).open, filename: File.basename(URI.parse(url).path))
rescue StandardError => e
  puts "  photo skipped for #{name_part}: #{e.class}"
end
photos_count = Zone.joins(:photos_attachments).distinct.count
puts "  zones: #{Zone.count}, price rules: #{PriceRule.count}, adjacencies: #{ZoneAdjacency.count}, photos: #{photos_count}"

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

    # избегаем пересечений внутри сидов: пропускаем, если слот занят.
    # Конец интервала расширен на максимальный буфер уборки (30 минут) —
    # именно с ним конфликт проверяет exclusion constraint в БД.
    next if zone.blocked?(starts_at..(ends_at + 30.minutes))

    user = (members + [ manager ]).sample(random:)
    status = case random.rand(10)
    when 0..6 then :confirmed
    when 7 then :pending
    when 8 then :cancelled
    else :declined
    end

    # Исторические демо-брони: валидация «только будущее» не для сидов,
    # пересечения всё равно исключены проверкой выше и constraint в БД.
    children_party = [ true, false, false, false ].sample(random:)
    reservation = Reservation.new(
      zone:, user:,
      starts_at:, ends_at:,
      guests_count: 1 + random.rand(zone.capacity),
      purpose: [ "Встреча с клиентом", "Рабочая сессия", "День рождения", "Мастер-класс", "Пленарное собрание" ].sample(random:),
      children_party:
    )
    reservation.cleaning_minutes = zone.cleaning_minutes_for(children_party:)
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
