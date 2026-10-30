# frozen_string_literal: true

module Web
  class ConversationsController < ApplicationController
    before_action :require_login
    before_action :set_bulletin, only: %i[new create]
    before_action :reject_self_conversation, only: %i[new create]

    def index
      @conversations = Conversation.visible_to(current_user)
                                   .includes(:bulletin, :buyer, :seller, :last_message)
                                   .order(updated_at: :desc, id: :desc)
                                   .page(params[:page]).per(20)
    end

    def show
      @conversation = Conversation.visible_to(current_user)
                                  .includes(:bulletin, :buyer, :seller)
                                  .find(params[:id])
      @messages = @conversation.messages.includes(:sender).order(:created_at, :id)
                               .page(params[:page]).per(50)
      @message = Message.new
    end

    def new
      @message = Message.new
    end

    def create
      ActiveRecord::Base.transaction do
        @conversation = @bulletin.conversations.create_or_find_by!(buyer: current_user) do |conversation|
          conversation.seller = @bulletin.user
        end
        @message = @conversation.messages.create!(sender: current_user, body: message_params[:body])
      end

      redirect_to conversation_path(@conversation), notice: 'Сообщение отправлено.'
    rescue ActiveRecord::RecordInvalid => error
      @message = error.record.is_a?(Message) ? error.record : Message.new(body: message_params[:body])
      @message.errors.add(:base, 'Не удалось создать переписку.') unless error.record.is_a?(Message)
      render :new, status: :unprocessable_entity
    end

    private

    def require_login
      redirect_to root_path, alert: t('flash.auth.sign_in') unless signed_in?
    end

    def set_bulletin
      @bulletin = Bulletin.published.includes(:user).find(params[:bulletin_id])
    end

    def reject_self_conversation
      return unless @bulletin.user_id == current_user.id

      redirect_to bulletin_path(@bulletin), alert: 'Нельзя писать самому себе.'
    end

    def message_params
      params.require(:message).permit(:body)
    end
  end
end
