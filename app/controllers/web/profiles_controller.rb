class Web::ProfilesController < ApplicationController
  before_action :require_login

  def show
    base = current_user.bulletins.includes(:category).recent
    @q = base.ransack(params[:q])
    @bulletins = @q.result(distinct: true).page(params[:page])
  end

  private

  def require_login
    return if signed_in?
    redirect_to root_path, alert: "Войдите в аккаунт"
  end
end
