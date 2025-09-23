# frozen_string_literal: true

module Web
  class AuthController < ApplicationController
    # POST /auth/:provider  (routes as: auth_request_path)
    def start
      redirect_to "/auth/#{params[:provider]}", allow_other_host: true
    end

    # GET /auth/:provider/callback
    def callback
      auth = @_request.env['omniauth.auth']
      info = auth && (auth['info'] || auth[:info]) || {}

      email = info['email'] || info[:email]
      if email.blank?
        return redirect_to root_path,
                           alert: 'GitHub не вернул email. Разрешите доступ к email на GitHub и попробуйте снова.'
      end

      user = User.find_or_initialize_by(email:)
      if user.new_record?
        user.name = info['name'] || info[:name] || email.split('@').first
        user.save!
      end

      admin_email = ENV['ADMIN_EMAIL']
      if admin_email.present? && email.to_s.casecmp(admin_email.to_s).zero? && !user.admin?
        user.update!(admin: true)
      end

      session[:user_id] = user.id
      redirect_to root_path, notice: 'Вы вошли через GitHub'
    rescue StandardError
      redirect_to root_path, alert: 'Не удалось войти через GitHub'
    end

    # DELETE /signout
    def destroy
      reset_session
      redirect_to root_path, notice: 'Вы вышли'
    end
  end
end
