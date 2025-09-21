class Web::ProfilesController < ApplicationController
  before_action :require_login

  def show
    @bulletins = current_user.bulletins.includes(:category).recent
    @bulletin  = Bulletin.new
  end

  private

  def require_login
    return if signed_in?
    redirect_to root_path, alert: "Войдите в аккаунт"
  end
end
