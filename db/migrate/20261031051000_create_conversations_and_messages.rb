# frozen_string_literal: true

class CreateConversationsAndMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :bulletin, null: false, foreign_key: true
      t.references :buyer, null: false, foreign_key: { to_table: :users }
      t.references :seller, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :conversations, [ :bulletin_id, :buyer_id ], unique: true
    add_index :conversations, [ :buyer_id, :updated_at ]
    add_index :conversations, [ :seller_id, :updated_at ]

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false
      t.timestamps
    end

    add_index :messages, [ :conversation_id, :created_at, :id ]
  end
end
