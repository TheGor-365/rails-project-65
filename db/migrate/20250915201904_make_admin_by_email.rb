class MakeAdminByEmail < ActiveRecord::Migration[7.2]
  def up
    email = ENV['ADMIN_EMAIL'].to_s.downcase.strip
    return if email.blank?

    User.where('lower(email) = ?', email).update_all(admin: true)
  end

  def down
    # no-op
  end
end
