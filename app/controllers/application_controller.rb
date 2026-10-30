# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization

  allow_browser versions: :modern
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
