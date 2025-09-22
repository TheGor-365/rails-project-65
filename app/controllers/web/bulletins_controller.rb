# frozen_string_literal: true

module Web
  class BulletinsController < ApplicationController
    before_action :require_login, only: %i[new create to_moderate archive]
    before_action :set_bulletin,  only: %i[to_moderate archive]

    def index
      base = Bulletin.published.includes(:category, :user).recent
      @q = base.ransack(params[:q])
      @bulletins = @q.result(distinct: true).page(params[:page])
    end

    def new
      @bulletin = Bulletin.new
    end

    def create
      @bulletin = current_user.bulletins.build(bulletin_params)
      if @bulletin.save
        redirect_to profile_path, notice: t('app.bulletins.created_draft')
      else
        render :new, status: :unprocessable_entity
      end
    end

    def to_moderate
      authorize @bulletin, :to_moderate?
      if @bulletin.to_moderate!
        redirect_to profile_path, notice: t('app.bulletins.sent_to_moderation')
      else
        redirect_to profile_path, alert: t('app.bulletins.send_to_moderation_failed')
      end
    end

    def archive
      authorize @bulletin, :archive?
      if @bulletin.archive!
        redirect_to profile_path, notice: t('app.bulletins.sent_to_archive')
      else
        redirect_to profile_path, alert: t('app.bulletins.send_to_archive_failed')
      end
    end

    private

    def set_bulletin
      @bulletin = current_user.bulletins.find(params[:id])
    end

    def bulletin_params
      params.require(:bulletin).permit(:title, :description, :category_id, :image)
    end

    def require_login
      return if signed_in?

      redirect_to root_path, alert: t('app.auth.sign_in_first')
    end
  end
end
