# frozen_string_literal: true

require 'test_helper'

module Web
  class UnreadMessagesTest < ActionDispatch::IntegrationTest
    setup do
      @conversation = Conversation.create!(
        bulletin: bulletins(:first), buyer: users(:two), seller: users(:one)
      )
    end

    test 'incoming first message is unread for author but not sender' do
      @conversation.messages.create!(sender: users(:two), body: 'Is it available?')

      assert_equal 1, Message.unread_for(users(:one)).count
      assert_equal 0, Message.unread_for(users(:two)).count
      assert_equal 0, Message.unread_for(users(:admin)).count

      sign_in(users(:one))
      get conversations_path
      assert_response :success
      assert_select '.cl-message-unread-badge', text: '1', count: 2
      assert_select '.cl-conversation-item--unread', count: 1
    end

    test 'reading thread clears badge, new incoming reply appears again' do
      initial = @conversation.messages.create!(sender: users(:two), body: 'First question')

      sign_in(users(:one))
      get conversation_path(@conversation)
      assert_response :success
      assert_equal initial.id, @conversation.reload.seller_last_read_message_id
      assert_equal 0, Message.unread_for(users(:one)).count
      assert_select '.cl-message-unread-badge', count: 0

      post conversation_messages_path(@conversation), params: { message: { body: 'Author answer' } }
      assert_redirected_to conversation_path(@conversation)
      assert_equal 1, Message.unread_for(users(:two)).count
      assert_equal 0, Message.unread_for(users(:one)).count

      sign_in(users(:two))
      get conversations_path
      assert_select '.cl-conversation-item--unread', count: 1
      get conversation_path(@conversation)
      assert_response :success
      assert_equal 0, Message.unread_for(users(:two)).count
    end

    test 'outsider cannot mark messages as read by opening guessed conversation URL' do
      @conversation.messages.create!(sender: users(:two), body: 'Private')
      sign_in(users(:admin))

      get conversation_path(@conversation)
      assert_response :not_found
      assert_nil @conversation.reload.seller_last_read_message_id
      assert_equal 1, Message.unread_for(users(:one)).count
      assert_select '.cl-message-unread-badge', count: 0
    end

    test 'older page does not acknowledge more recent messages outside that page' do
      51.times do |index|
        @conversation.messages.create!(sender: users(:two), body: "Question #{index}")
      end

      sign_in(users(:one))
      get conversation_path(@conversation)

      assert_response :success
      assert_equal @conversation.messages.order(:created_at, :id).limit(50).last.id,
                   @conversation.reload.seller_last_read_message_id
      assert_equal 1, Message.unread_for(users(:one)).count

      get conversation_path(@conversation), params: { page: 2 }
      assert_response :success
      assert_equal 0, Message.unread_for(users(:one)).count
    end
  end
end
