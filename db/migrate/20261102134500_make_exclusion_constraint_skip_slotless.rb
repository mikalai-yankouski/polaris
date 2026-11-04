class MakeExclusionConstraintSkipSlotless < ActiveRecord::Migration[8.1]
  # tsrange(NULL, NULL) даёт бесконечный интервал: заявка без времени
  # конфликтовала бы со всеми бронями зоны. Пересечения проверяем только у заявок со слотом.
  def change
    remove_exclusion_constraint :reservations, name: "reservations_no_overlaps"
    add_exclusion_constraint :reservations,
                             "zone_id WITH =, tsrange(starts_at, ends_at + make_interval(mins => cleaning_minutes), '[)') WITH &&",
                             using: :gist,
                             where: "status IN (0, 1) AND starts_at IS NOT NULL AND ends_at IS NOT NULL",
                             name: "reservations_no_overlaps"
  end
end
