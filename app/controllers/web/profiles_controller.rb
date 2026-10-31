# frozen_string_literal: true

module Web
  class ProfilesController < ApplicationController
    before_action :require_login

    def show
      base = current_user.bulletins.includes(:category).recent
      @state_counts = current_user.bulletins.group(:state).count
      @categories = Category.order(:name)
      @q = base.ransack(params[:q])
      @bulletins = @q.result(distinct: true).page(params[:page])
    end

    private

    def require_login
      return if signed_in?

      redirect_to root_path, alert: t('profiles.login_required')
    end
  end
end
