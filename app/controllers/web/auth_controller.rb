# frozen_string_literal: true

module Web
  class AuthController < ApplicationController
    def request
      redirect_to "/auth/#{params[:provider]}", allow_other_host: true
    end

    def callback
      auth  = fetch_auth or (return auth_failed)
      email = extract_email(auth) or (return no_email)

      user = find_or_create_user(email, auth)
      promote_to_admin!(user, email)
      sign_in(user)

      signed_in_ok
    rescue StandardError => e
      Rails.logger.error("[AuthController] callback error: #{e.class}: #{e.message}")
      auth_failed
    end

    def destroy
      reset_session
      redirect_to root_path, notice: t('app.auth.signed_out')
    end

    private

    def fetch_auth
      request.env['omniauth.auth']
    end

    def sign_in(user)
      session[:user_id] = user.id
    end

    def signed_in_ok
      redirect_to root_path, notice: t('app.auth.signed_in')
    end

    def auth_failed
      redirect_to root_path, alert: t('app.auth.github_failed')
    end

    def no_email
      redirect_to root_path, alert: t('app.auth.github_no_email')
    end

    def find_or_create_user(email, auth)
      user = User.find_or_initialize_by(email: email)
      name = auth.dig('info', 'name')
      user.name = name if user.name.blank? && name.present?
      user.save! if user.changed?
      user
    end

    def extract_email(auth)
      info_email = auth.dig('info', 'email')
      return info_email if info_email.present?

      emails  = auth.dig('extra', 'all_emails')
      primary = emails&.find { |h| h['primary'] }
      primary && primary['email']
    end

    def promote_to_admin!(user, email)
      admin_email = ENV.fetch('ADMIN_EMAIL', nil)&.downcase
      return unless admin_email.present? && email.to_s.casecmp?(admin_email)
      return if user.admin?

      user.update!(admin: true)
    end
  end
end
