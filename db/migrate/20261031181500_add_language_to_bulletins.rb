# frozen_string_literal: true

class AddLanguageToBulletins < ActiveRecord::Migration[8.1]
  def change
    # The existing demo listings were authored in Russian. A non-null database
    # default safely labels existing rows without editing their content.
    add_column :bulletins, :language, :string, default: 'ru', null: false
  end
end
