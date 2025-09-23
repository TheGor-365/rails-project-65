# frozen_string_literal: true

module Web
  class BulletinsController < ApplicationController
    before_action :set_bulletin, only: %i[show edit update to_moderate archive]
    before_action :authenticate!, only: %i[new create edit update to_moderate archive]

    def index
      @q = Bulletin.published.ransack(params[:q])
      @categories = Category.order(:name)
      @bulletins = @q.result(distinct: true).page(params[:page]).per(12)
    end

    def show; end

    def new
      @bulletin = current_user.bulletins.build
      @categories = Category.order(:name)
    end

    def edit
      authorize @bulletin
      @categories = Category.order(:name)
    end

    def create
      @bulletin = current_user.bulletins.build(bulletin_params)
      if @bulletin.save
        redirect_to profile_path, notice: t('flash.bulletins.created_draft')
      else
        @categories = Category.order(:name)
        render :new, status: :unprocessable_entity
      end
    end

    def update
      authorize @bulletin
      if @bulletin.update(bulletin_params)
        redirect_to profile_path, notice: t('flash.bulletins.sent_to_moderation')
      else
        @categories = Category.order(:name)
        render :edit, status: :unprocessable_entity
      end
    end

    def to_moderate
      authorize @bulletin
      if @bulletin.may_to_moderate?
        @bulletin.to_moderate!
        redirect_to profile_path, notice: t('flash.bulletins.sent_to_moderation')
      else
        redirect_to profile_path, alert: t('flash.bulletins.send_failed')
      end
    end

    def archive
      authorize @bulletin
      if @bulletin.may_archive?
        @bulletin.archive!
        redirect_to profile_path, notice: t('flash.bulletins.archived')
      else
        redirect_to profile_path, alert: t('flash.bulletins.archive_failed')
      end
    end

    private

    def set_bulletin
      @bulletin = Bulletin.find(params[:id])
    end

    def authenticate!
      redirect_to root_path, alert: 'Войдите в аккаунт' unless signed_in?
    end

    def bulletin_params
      params.require(:bulletin).permit(:title, :description, :category_id, :image)
    end
  end
end
