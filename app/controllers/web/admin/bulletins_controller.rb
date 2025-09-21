class Web::Admin::BulletinsController < Web::Admin::BaseController
  before_action :set_bulletin, only: %i[show edit update destroy publish reject archive]

  def index
    @bulletins = Bulletin.includes(:category, :user).order(created_at: :desc)
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
    authorize @bulletin, :publish?
    if @bulletin.publish!
      redirect_to admin_bulletins_path, notice: "Опубликовано"
    else
      redirect_to admin_bulletins_path, alert: "Не удалось опубликовать"
    end
  end

  def reject
    authorize @bulletin, :reject?
    if @bulletin.reject!
      redirect_to admin_bulletins_path, notice: "Отклонено"
    else
      redirect_to admin_bulletins_path, alert: "Не удалось отклонить"
    end
  end

  def archive
    if @bulletin.may_archive?
      @bulletin.archive!
      redirect_to admin_bulletins_path, notice: "В архиве"
    else
      redirect_to admin_bulletins_path, alert: "Не удалось отправить в архив"
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
