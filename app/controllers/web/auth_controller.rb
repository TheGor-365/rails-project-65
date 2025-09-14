class Web::AuthController < ApplicationController
  # GET /auth/:provider/callback
  def callback
    auth = request.env['omniauth.auth']
    info = auth && auth['info'] || {}

    email = info['email'].to_s.downcase
    name  = info['name'].to_s

    user = User.find_or_initialize_by(email: email)
    user.name = name if user.name.blank?
    user.save! if user.changed?

    session[:user_id] = user.id
    redirect_to root_path
  end

  def destroy
    reset_session
    redirect_to root_path, notice: 'Вы вышли из аккаунта'
  end
end
