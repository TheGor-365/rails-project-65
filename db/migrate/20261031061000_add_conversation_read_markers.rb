# frozen_string_literal: true

class AddConversationReadMarkers < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :buyer_last_read_message_id, :integer
    add_column :conversations, :seller_last_read_message_id, :integer
  end
end
