class CreateOauthIdentities < ActiveRecord::Migration[7.2]
  def change
    create_table :oauth_identities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false

      t.timestamps

      t.index [:provider, :uid], unique: true
    end
  end
end
