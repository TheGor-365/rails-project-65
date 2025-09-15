class ApplicationController < ActionController::Base
  include Pundit::Authorization

  allow_browser versions: :modern
  helper_method :current_user, :signed_in?

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def signed_in?
    current_user.present?
  end

  rescue_from Pundit::NotAuthorizedError do
    redirect_to root_path, alert: 'Недостаточно прав'
  end
end
