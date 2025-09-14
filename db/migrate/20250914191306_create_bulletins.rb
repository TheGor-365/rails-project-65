class CreateBulletins < ActiveRecord::Migration[7.2]
  def change
    create_table :bulletins do |t|
      t.string     :title,       null: false, limit: 50
      t.text       :description, null: false
      t.references :category,    null: false, foreign_key: true
      t.references :user,        null: false, foreign_key: true

      t.timestamps
    end
    add_index :bulletins, :created_at
  end
end
