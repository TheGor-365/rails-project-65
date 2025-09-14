class Web::BulletinsController < ApplicationController
  before_action :require_login, only: %i[new create]

  def index
    @bulletins = Bulletin.includes(:category, :user).recent
  end

  def new
    @bulletin = Bulletin.new
  end

  def create
    @bulletin = current_user.bulletins.build(bulletin_params)

    if @bulletin.save
      redirect_to root_path, notice: 'Объявление создано'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def bulletin_params
    params.require(:bulletin).permit(:title, :description, :category_id, :image)
  end

  def require_login
    return if signed_in?

    redirect_to root_path, alert: 'Для создания объявления войдите через GitHub'
  end
end
