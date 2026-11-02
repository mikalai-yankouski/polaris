FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "Пользователь #{n}" }
    sequence(:email_address) { |n| "user#{n}@polaris.test" }
    password { "password123" }

    trait :manager do
      role { :manager }
    end

    trait :admin do
      role { :admin }
    end
  end

  factory :building do
    sequence(:name) { |n| "Здание #{n}" }
  end

  factory :amenity do
    sequence(:name) { |n| "Удобство #{n}" }
  end

  factory :zone do
    association :building
    sequence(:name) { |n| "Зона #{n}" }
    description { "Описание зоны" }
    capacity { 10 }
    floor { 2 }
    hourly_rate_cents { 5000 } # 50 BYN/час
    min_duration_minutes { 60 }
    max_duration_minutes { 480 }
    requires_approval { true }
    active { true }
  end

  factory :reservation do
    association :zone, requires_approval: true
    association :user
    starts_at { 1.day.from_now.change(hour: 10, min: 0, sec: 0) }
    ends_at { 1.day.from_now.change(hour: 12, min: 0, sec: 0) }
    guests_count { 2 }
    purpose { "Встреча" }

    trait :confirmed do
      after(:create) { |reservation| reservation.update_column(:status, Reservation.statuses[:confirmed]) }
    end

    trait :auto_zone do
      association :zone, requires_approval: false
    end
  end
end
