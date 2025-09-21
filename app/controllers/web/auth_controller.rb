# frozen_string_literal: true

class Web::AuthController < ApplicationController
  # POST /auth/:provider
  def oauth
    redirect_to "/auth/#{params[:provider]}"
  end

  # GET /auth/:provider/callback
  def callback
    auth = request.env['omniauth.auth'] || {}
    info = auth['info'] || {}
    raw  = (auth.dig('extra', 'raw_info') || {})

    email = (info['email'].presence || raw['email'].presence).to_s.downcase.strip
    nickname = info['nickname'].presence || raw['login'].presence
    name = info['name'].presence || nickname || 'User'

    if email.blank?
      Rails.logger.warn('[Auth] GitHub не вернул email — проверь scope user:email в omniauth и настройки GitHub.')
      redirect_to root_path, alert: 'GitHub не вернул email. Разрешите доступ к email на GitHub и попробуйте снова.'
      return
    end

    user = User.find_or_initialize_by(email: email)
    user.name = name if user.name.blank?
    user.save!

    admin_email = ENV['ADMIN_EMAIL'].to_s.downcase.strip
    if admin_email.present? && email == admin_email && !user.admin?
      user.update_column(:admin, true)
    end

    session[:user_id] = user.id
    redirect_to root_path, notice: 'Вы вошли через GitHub'
  rescue => e
    Rails.logger.error("[Auth] Ошибка GitHub OAuth: #{e.class}: #{e.message}")
    redirect_to root_path, alert: 'Не удалось войти через GitHub'
  end

  # DELETE /signout
  def destroy
    reset_session
    redirect_to root_path, notice: 'Вы вышли'
  end
end
