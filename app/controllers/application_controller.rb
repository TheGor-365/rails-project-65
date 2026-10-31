# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization

  allow_browser versions: :modern
  around_action :switch_locale

  # Existing default-Russian URLs remain unchanged; nondefault locales
  # propagate through Rails route helpers (including post-redirect-get).
  def default_url_options
    I18n.locale == I18n.default_locale ? {} : { locale: I18n.locale }
  end

  private

  def switch_locale(&action)
    allowed = I18n.available_locales.map(&:to_s)
    requested = params[:locale]
    session[:locale] = requested if requested.is_a?(String) && allowed.include?(requested)

    preference = session[:locale]
    locale = allowed.include?(preference) ? preference : I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  public
  helper_method :current_user, :signed_in?, :unread_messages_count

  def unread_messages_count
    return 0 unless signed_in?

    @unread_messages_count ||= Message.unread_for(current_user).count
  end

  def current_user
    return @current_user if defined?(@current_user)

    user_id = session[:user_id]
    @current_user = if user_id.present? &&
                       session[:oauth_verified_user_id] == user_id
                      User.find_by(id: user_id)
    end
  end

  def signed_in?
    current_user.present?
  end

  rescue_from Pundit::NotAuthorizedError do
    redirect_to root_path, alert: t('app.errors.not_authorized')
  end
end
