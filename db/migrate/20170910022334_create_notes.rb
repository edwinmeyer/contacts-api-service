class CreateNotes < ActiveRecord::Migration[5.1]
  def change
    create_table :notes do |t|
      t.datetime :note_date
      t.text :content
      t.references :contact, foreign_key: true

      t.timestamps
    end
  end
end
