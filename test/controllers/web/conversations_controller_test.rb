# frozen_string_literal: true

require 'test_helper'

module Web
  class ConversationsControllerTest < ActionDispatch::IntegrationTest
    test 'guest cannot read inbox or start conversation' do
      get conversations_path
      assert_redirected_to root_path

      get new_bulletin_conversation_path(bulletins(:first))
      assert_redirected_to root_path

      post bulletin_conversations_path(bulletins(:first)), params: { message: { body: 'Hello' } }
      assert_redirected_to root_path
      assert_equal 0, Conversation.count
    end

    test 'published bulletin allows first message and reuses existing dialogue' do
      sign_in(users(:two))
      get new_bulletin_conversation_path(bulletins(:first))
      assert_response :success
      assert_select 'textarea[name="message[body]"]'

      assert_difference [ 'Conversation.count', 'Message.count' ], 1 do
        post bulletin_conversations_path(bulletins(:first)),
             params: { message: { body: '  Здравствуйте, актуально?  ' } }
      end

      conversation = Conversation.last
      assert_redirected_to conversation_path(conversation)
      assert_equal users(:two), conversation.buyer
      assert_equal users(:one), conversation.seller
      assert_equal 'Здравствуйте, актуально?', conversation.messages.first.body

      assert_no_difference 'Conversation.count' do
        assert_difference 'Message.count', 1 do
          post bulletin_conversations_path(bulletins(:first)),
               params: { message: { body: 'Возможна доставка?' } }
        end
      end
    end

    test 'own listing and unpublished listing do not start chat' do
      sign_in(users(:one))
      get new_bulletin_conversation_path(bulletins(:first))
      assert_redirected_to bulletin_path(bulletins(:first))

      post bulletin_conversations_path(bulletins(:first)),
           params: { message: { body: 'Test' } }
      assert_redirected_to bulletin_path(bulletins(:first))

      get new_bulletin_conversation_path(bulletins(:second))
      assert_response :not_found
      assert_equal 0, Conversation.count
    end

    test 'invalid first message rolls back new conversation' do
      sign_in(users(:two))

      assert_no_difference [ 'Conversation.count', 'Message.count' ] do
        post bulletin_conversations_path(bulletins(:first)),
             params: { message: { body: '   ' } }
      end

      assert_response :unprocessable_entity
      assert_select 'textarea[name="message[body]"]'
    end

    test 'inbox, conversation and reply are visible only to participants' do
      conversation = Conversation.create!(bulletin: bulletins(:first), buyer: users(:two), seller: users(:one))
      conversation.messages.create!(sender: users(:two), body: 'Private details')

      sign_in(users(:admin))
      get conversations_path
      assert_response :success
      assert_select 'a[href=?]', conversation_path(conversation), count: 0
      get conversation_path(conversation)
      assert_response :not_found
      post conversation_messages_path(conversation), params: { message: { body: 'Intrusion' } }
      assert_response :not_found

      sign_in(users(:one))
      get conversations_path
      assert_response :success
      assert_select 'a[href=?]', conversation_path(conversation)
      get conversation_path(conversation)
      assert_response :success
      assert_select '.cl-message-bubble__body', text: /Private details/

      post conversation_messages_path(conversation),
           params: { message: { body: '<script>alert(1)</script>', sender_id: users(:two).id } }
      assert_redirected_to conversation_path(conversation)
      assert_equal users(:one), conversation.messages.order(:id).last.sender
      get conversation_path(conversation)
      assert_select '.cl-message-bubble__body', text: /<script>alert\(1\)<\/script>/
      assert_no_match(/<script>alert\(1\)<\/script>/, response.body)

      sign_in(users(:two))
      get conversations_path
      assert_select 'a[href=?]', conversation_path(conversation)
    end

    test 'message validates identity and length' do
      conversation = Conversation.create!(bulletin: bulletins(:first), buyer: users(:two), seller: users(:one))
      assert_not Message.new(conversation: conversation, sender: users(:admin), body: 'Hello').valid?
      assert_not Message.new(conversation: conversation, sender: users(:two), body: 'x' * 2001).valid?
      assert_equal 0, Message.count
    end

    test 'archived listing keeps existing private conversation available' do
      conversation = Conversation.create!(bulletin: bulletins(:first), buyer: users(:two), seller: users(:one))
      conversation.messages.create!(sender: users(:two), body: 'Before archive')
      bulletins(:first).archive!

      sign_in(users(:two))
      get conversation_path(conversation)
      assert_response :success
      post conversation_messages_path(conversation), params: { message: { body: 'Follow-up' } }
      assert_redirected_to conversation_path(conversation)
    end
  end
end
