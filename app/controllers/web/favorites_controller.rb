# frozen_string_literal: true
module Web
  class FavoritesController < ApplicationController
    before_action :require_sign_in

    def index
      @favorites = current_user.favorites.joins(:bulletin)
                               .where(bulletins: { state: 'published' })
                               .includes(bulletin: [ :category, { image_attachment: :blob } ])
                               .order(created_at: :desc).page(params[:page]).per(12)
    end

    def create
      bulletin = Bulletin.published.find(params[:bulletin_id])
      current_user.favorites.find_or_create_by!(bulletin: bulletin)
      redirect_to bulletin_path(bulletin), notice: 'Объявление добавлено в избранное.'
    end

    def destroy
      bulletin = Bulletin.find(params[:bulletin_id])
      current_user.favorites.where(bulletin: bulletin).destroy_all
      redirect_to bulletin.published? ? bulletin_path(bulletin) : favorites_path,
                  notice: 'Объявление убрано из избранного.'
    end

    private

    def require_sign_in
      redirect_to root_path, alert: t('flash.auth.sign_in') unless signed_in?
    end
  end
end
