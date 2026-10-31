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
      ids = @conversations.map(&:id)
      @unread_counts = ids.any? ? Message.unread_for(current_user).where(conversation_id: ids)
                                  .group(:conversation_id).count : {}
    end

    def show
      @conversation = Conversation.visible_to(current_user)
                                  .includes(:bulletin, :buyer, :seller)
                                  .find(params[:id])
      @messages = @conversation.messages.includes(:sender).order(:created_at, :id)
                               .page(params[:page]).per(50)
      @conversation.mark_read_for!(current_user, upto_message_id: @messages.last&.id)
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

      redirect_to conversation_path(@conversation), notice: t('flash.conversations.message_sent')
    rescue ActiveRecord::RecordInvalid => error
      @message = error.record.is_a?(Message) ? error.record : Message.new(body: message_params[:body])
      @message.errors.add(:base, t('flash.conversations.create_failed')) unless error.record.is_a?(Message)
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

      redirect_to bulletin_path(@bulletin), alert: t('flash.conversations.self_conversation')
    end

    def message_params
      params.require(:message).permit(:body)
    end
  end
end
