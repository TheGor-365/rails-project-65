# frozen_string_literal: true

class AddStateToBulletins < ActiveRecord::Migration[7.2]
  def change
    add_column :bulletins, :state, :string, null: false, default: 'draft'
    add_index  :bulletins, :state
  end
end
