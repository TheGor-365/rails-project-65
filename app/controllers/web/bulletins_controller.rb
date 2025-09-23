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

    def create
      @bulletin = current_user.bulletins.build(bulletin_params)
      if @bulletin.save
        redirect_to profile_path, notice: 'Объявление создано как черновик'
      else
        @categories = Category.order(:name)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @bulletin
      @categories = Category.order(:name)
    end

    def update
      authorize @bulletin
      if @bulletin.update(bulletin_params)
        redirect_to profile_path, notice: 'Отправлено на модерацию'
      else
        @categories = Category.order(:name)
        render :edit, status: :unprocessable_entity
      end
    end

    def to_moderate
      authorize @bulletin
      if @bulletin.may_to_moderate?
        @bulletin.to_moderate!
        redirect_to profile_path, notice: 'Отправлено на модерацию'
      else
        redirect_to profile_path, alert: 'Не удалось отправить на модерацию'
      end
    end

    def archive
      authorize @bulletin
      if @bulletin.may_archive?
        @bulletin.archive!
        redirect_to profile_path, notice: 'Отправлено в архив'
      else
        redirect_to profile_path, alert: 'Не удалось отправить в архив'
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
