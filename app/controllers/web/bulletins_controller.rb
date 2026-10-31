# frozen_string_literal: true

module Web
  class BulletinsController < ApplicationController
    include BulletinPhotoUploads
    before_action :set_bulletin, only: %i[show edit update to_moderate archive]
    before_action :authenticate!, only: %i[new create edit update to_moderate archive]

    def index
      @q = Bulletin.published.ransack(params[:q])
      @categories = Category.order(:name)
      @sort = %w[newest oldest title_asc title_desc].include?(params[:sort]) ? params[:sort] : 'newest'
      ordering = {
        'newest' => { created_at: :desc, id: :desc },
        'oldest' => { created_at: :asc, id: :asc },
        'title_asc' => { title: :asc, id: :desc },
        'title_desc' => { title: :desc, id: :desc }
      }.fetch(@sort)
      @bulletins = @q.result(distinct: true).reorder(ordering)
                     .includes(:category).with_attached_image.page(params[:page]).per(12)
    end

    def show
      authorize @bulletin
    end

    def new
      @bulletin = current_user.bulletins.build(language: I18n.locale.to_s)
      @categories = Category.order(:name)
    end

    def edit
      authorize @bulletin
      @categories = Category.order(:name)
    end

    def create
      attributes = bulletin_params
      @bulletin = current_user.bulletins.build(attributes)
      @bulletin.language = I18n.locale.to_s unless attributes.key?(:language)
      assign_uploaded_photos(@bulletin)
      if @bulletin.save
        redirect_to profile_path, notice: t('flash.bulletins.created_draft')
      else
        @categories = Category.order(:name)
        render :new, status: :unprocessable_entity
      end
    end

    def update
      authorize @bulletin
      assign_uploaded_photos(@bulletin)
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
      redirect_to root_path, alert: t('flash.auth.sign_in') unless signed_in?
    end

    def bulletin_params
      params.require(:bulletin).permit(:title, :description, :category_id, :language, :image)
    end
  end
end
