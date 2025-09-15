class Web::Admin::BulletinsController < Web::Admin::BaseController
  before_action :set_bulletin, only: %i[edit update destroy]

  def index
    @bulletins = Bulletin.includes(:category, :user).order(created_at: :desc)
  end

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

  private

  def set_bulletin
    @bulletin = Bulletin.find(params[:id])
  end

  def bulletin_params
    params.require(:bulletin).permit(:title, :description, :category_id, :image)
  end
end
