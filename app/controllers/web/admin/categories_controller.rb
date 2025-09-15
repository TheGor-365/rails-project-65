class Web::Admin::CategoriesController < Web::Admin::BaseController
  before_action :set_category, only: %i[edit update destroy]

  def index
    @categories = Category.order(:name)
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      redirect_to admin_categories_path, notice: 'Категория создана'
    else
      @categories = Category.order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @category.update(category_params)
      redirect_to admin_categories_path, notice: 'Категория обновлена'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category.destroy
    redirect_to admin_categories_path, notice: 'Категория удалена'
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name)
  end
end
