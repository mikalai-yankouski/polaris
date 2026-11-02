class AddRoomAttributesToZones < ActiveRecord::Migration[8.1]
  def change
    # Тип комнаты: кинокомната / караоке / бильярд / лаундж / приставочная
    add_column :zones, :room_type, :integer, null: false, default: 0
    # Номер по зданию, например «2-8» (этаж-комната)
    add_column :zones, :building_code, :string
    # Буфер уборки после брони, минут (после детских — 30 через флаг брони)
    add_column :zones, :cleaning_buffer_minutes, :integer, null: false, default: 15
  end
end
