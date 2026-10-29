# frozen_string_literal: true

module Web
  class AuthController < ApplicationController
    # POST /auth/:provider  (routes as: auth_request_path)
    def start
      redirect_to "/auth/#{params[:provider]}", allow_other_host: true
    end

    def callback
      auth = request.env['omniauth.auth']
      return oauth_failure unless valid_github_callback?(auth)

      info = auth['info'] || {}
      email = info['email'].to_s.strip.downcase
      return oauth_failure if email.blank?

      uid = auth['uid'].to_s
      user = if session[:oauth_link_user_id].present?
               link_github_account(uid)
      else
               github_account(uid, email, info['name'])
      end

      return oauth_failure unless user

      complete_login(user)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      oauth_failure
    end

    def link_form
      return if verified_oauth_session?

      redirect_to root_path, alert: t('flash.auth.no_rights')
    end

    def prepare_link
      return redirect_to(root_path, alert: t('flash.auth.no_rights')) unless verified_oauth_session?

      session[:oauth_link_user_id] = current_user.id
      render :prepare_link
    end

    # DELETE /signout
    def destroy
      reset_session
      redirect_to root_path, notice: t('flash.auth.logged_out')
    end
    private

    def verified_oauth_session?
      signed_in? && session[:oauth_verified_user_id] == current_user.id
    end

    def valid_github_callback?(auth)
      auth.present? &&
        params[:provider] == 'github' &&
        auth['provider'] == 'github' &&
        auth['uid'].present?
    end

    def github_account(uid, email, name)
      identity = OauthIdentity.includes(:user).find_by(
        provider: 'github', uid: uid
      )
      return identity.user if identity

      return if User.where('LOWER(email) = ?', email).exists?

      User.transaction do
        user = User.create!(
          email: email,
          name: name.presence || email.split('@').first
        )
        user.oauth_identities.create!(provider: 'github', uid: uid)
        user
      end
    end

    def link_github_account(uid)
      return unless verified_oauth_session?
      return unless session[:oauth_link_user_id] == current_user.id

      identity = OauthIdentity.find_by(provider: 'github', uid: uid)
      return if identity && identity.user_id != current_user.id

      if identity.nil?
        return if current_user.oauth_identities.exists?(provider: 'github')

        current_user.oauth_identities.create!(provider: 'github', uid: uid)
      end

      current_user
    end

    def complete_login(user)
      reset_session
      session[:user_id] = user.id
      session[:oauth_verified_user_id] = user.id
      redirect_to root_path, notice: t('flash.auth.github_login_success')
    end

    def oauth_failure
      redirect_to root_path, alert: t('flash.auth.github_login_fail')
    end
  end
end
