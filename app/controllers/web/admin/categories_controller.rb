# frozen_string_literal: true

module Web
  module Admin
    class CategoriesController < Web::Admin::BaseController
      before_action :set_category, only: %i[edit update destroy]

      def index
        @categories = Category.order(:name)
        @category = Category.new
      end

      def edit; end

      def create
        @category = Category.new(category_params)
        if @category.save
          redirect_to admin_categories_path, notice: t('admin.categories.created')
        else
          @categories = Category.order(:name)
          render :index, status: :unprocessable_entity
        end
      end

      def update
        if @category.update(category_params)
          redirect_to admin_categories_path, notice: t('admin.categories.updated')
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @category.destroy
        redirect_to admin_categories_path, notice: t('admin.categories.deleted')
      end

      private

      def set_category
        @category = Category.find(params[:id])
      end

      def category_params
        params.require(:category).permit(:name)
      end
    end
  end
end
