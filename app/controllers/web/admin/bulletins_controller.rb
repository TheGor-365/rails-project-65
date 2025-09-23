# frozen_string_literal: true

module Web
  module Admin
    class BulletinsController < BaseController
      before_action :set_bulletin, only: %i[publish reject archive edit update show destroy]

      def index
        @q = Bulletin.ransack(params[:q])
        @bulletins = @q.result.order(created_at: :desc).page(params[:page]).per(20)
      end

      def show; end
      def edit; end

      def update
        if @bulletin.update(bulletin_params)
          redirect_to admin_bulletins_path, notice: 'Объявление обновлено'
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @bulletin.destroy
        redirect_to admin_bulletins_path, notice: 'Объявление удалено'
      end

      def publish
        if @bulletin.may_publish?
          @bulletin.publish!
          redirect_to admin_bulletins_path, notice: 'Опубликовано'
        else
          redirect_to admin_bulletins_path, alert: 'Не удалось опубликовать'
        end
      end

      def reject
        if @bulletin.may_reject?
          @bulletin.reject!
          redirect_to admin_bulletins_path, notice: 'Отклонено'
        else
          redirect_to admin_bulletins_path, alert: 'Не удалось отклонить'
        end
      end

      def archive
        if @bulletin.may_archive?
          @bulletin.archive!
          redirect_to admin_bulletins_path, notice: 'В архиве'
        else
          redirect_to admin_bulletins_path, alert: 'Не удалось отправить в архив'
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
