# frozen_string_literal: true

module Web
  module Admin
    class BulletinsController < Web::Admin::BaseController
      before_action :set_bulletin, only: %i[show edit update destroy publish reject archive]

      def index
        base = Bulletin.includes(:category, :user).order(created_at: :desc)
        @q = base.ransack(params[:q])
        @bulletins = @q.result(distinct: true).page(params[:page])
      end

      def show; end

      def edit; end

      def update
        if @bulletin.update(bulletin_params)
          redirect_to admin_bulletins_path, notice: t('admin.bulletins.updated')
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @bulletin.destroy
        redirect_to admin_bulletins_path, notice: t('admin.bulletins.deleted')
      end

      def publish
        authorize @bulletin, :publish?
        if @bulletin.publish!
          redirect_to admin_bulletins_path, notice: t('admin.bulletins.published')
        else
          redirect_to admin_bulletins_path, alert:  t('admin.bulletins.publish_failed')
        end
      end

      def reject
        authorize @bulletin, :reject?
        if @bulletin.reject!
          redirect_to admin_bulletins_path, notice: t('admin.bulletins.rejected')
        else
          redirect_to admin_bulletins_path, alert:  t('admin.bulletins.reject_failed')
        end
      end

      def archive
        if @bulletin.may_archive?
          @bulletin.archive!
          redirect_to admin_bulletins_path, notice: t('admin.bulletins.archived')
        else
          redirect_to admin_bulletins_path, alert:  t('admin.bulletins.archive_failed')
        end
      end

      private

      def set_bulletin
        @bulletin = Bulletin.find(params[:id])
      end

      def bulletin_params
        params.require(:bulletin).permit(:title, :description, :category_id, :image)
      end
    end
  end
end
