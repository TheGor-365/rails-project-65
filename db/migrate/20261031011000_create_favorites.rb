# frozen_string_literal: true
class CreateFavorites < ActiveRecord::Migration[8.1]
  def change
    create_table :favorites do |t|
      t.integer :user_id, null: false
      t.integer :bulletin_id, null: false
      t.timestamps
    end

    add_index :favorites, [ :user_id, :bulletin_id ], unique: true
    add_index :favorites, :bulletin_id
    add_foreign_key :favorites, :users
    add_foreign_key :favorites, :bulletins
  end
end
