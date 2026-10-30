# frozen_string_literal: true

module Web
  class MessagesController < ApplicationController
    before_action :require_login

    def create
      @conversation = Conversation.visible_to(current_user).find(params[:conversation_id])
      @message = @conversation.messages.build(sender: current_user, body: message_params[:body])

      if @message.save
        redirect_to conversation_path(@conversation), notice: 'Сообщение отправлено.'
      else
        @messages = @conversation.messages.persisted.includes(:sender)
                                 .order(:created_at, :id).page(params[:page]).per(50)
        render 'web/conversations/show', status: :unprocessable_entity
      end
    end

    private

    def require_login
      redirect_to root_path, alert: t('flash.auth.sign_in') unless signed_in?
    end

    def message_params
      params.require(:message).permit(:body)
    end
  end
end
