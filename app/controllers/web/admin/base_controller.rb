class Web::Admin::BaseController < ApplicationController
  before_action :require_login
  before_action :authorize_admin!

  private

  def require_login
    return if signed_in?
    redirect_to root_path, alert: 'Войдите в аккаунт'
  end

  def authorize_admin!
    authorize :admin, :access?
  end
end
