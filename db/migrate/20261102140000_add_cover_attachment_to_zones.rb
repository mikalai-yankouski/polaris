class AddCoverAttachmentToZones < ActiveRecord::Migration[8.1]
  # Обложка зала в каталоге: id вложения ActiveStorage.
  # NULL = первое из photos (порядок загрузки).
  def change
    add_column :zones, :cover_attachment_id, :bigint
    add_index :zones, :cover_attachment_id
  end
end
