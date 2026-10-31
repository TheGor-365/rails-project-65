# frozen_string_literal: true

require 'test_helper'

module Web
  class ConversationsI18nTest < ActionDispatch::IntegrationTest
    test 'new conversation form and success notice are localized in three languages' do
      sign_in(users(:two))

      {
        ru: [ 'Новое сообщение', 'Отправить сообщение', 'Сообщение отправлено.' ],
        en: [ 'New message', 'Send message', 'Message sent.' ],
        hy: [ 'Նոր հաղորդագրություն', 'Ուղարկել հաղորդագրությունը', 'Հաղորդագրությունն ուղարկված է։' ]
      }.each do |locale, expected|
        get new_bulletin_conversation_path(bulletins(:first), locale: locale)

        assert_response :success
        assert_select "html[lang='#{locale}']"
        assert_select 'h2', text: expected[0]
        assert_select 'textarea[name="message[body]"]'
        assert_select "input[type='submit'][value=?]", expected[1]

        body = 'Actual author-provided message / исходный текст'
        assert_difference 'Message.count', 1 do
          post bulletin_conversations_path(bulletins(:first), locale: locale),
               params: { message: { body: body } }
        end

        expected_path = locale == :ru ? conversation_path(Conversation.last) : conversation_path(Conversation.last, locale: locale)
        assert_redirected_to expected_path
        follow_redirect!
        assert_select '.alert', text: /#{Regexp.escape(expected[2])}/
        assert_select '.cl-message-bubble__body', text: body
      end
    end

    test 'inbox, discussion and reply labels are translated without translating user text' do
      conversation = Conversation.create!(bulletin: bulletins(:first), buyer: users(:two), seller: users(:one))
      conversation.messages.create!(sender: users(:one), body: 'Untranslated private message')
      sign_in(users(:two))

      {
        ru: [ 'Переписки', 'Ответить', 'Текст сообщения', 'Все переписки' ],
        en: [ 'Conversations', 'Reply', 'Message text', 'All conversations' ],
        hy: [ 'Նամակագրություն', 'Պատասխանել', 'Հաղորդագրության տեքստ', 'Բոլոր զրույցները' ]
      }.each do |locale, words|
        get conversations_path(locale: locale)
        assert_response :success
        assert_select 'h2', text: words[0]
        assert_select 'a.cl-conversation-item', text: /#{Regexp.escape(bulletins(:first).title)}/

        get conversation_path(conversation, locale: locale)
        assert_response :success
        assert_select "html[lang='#{locale}']"
        assert_select '.cl-message-bubble__body', text: 'Untranslated private message'
        assert_select 'h3', text: words[1]
        assert_select 'label[for="message_body"]', text: words[2]
        assert_select '.cl-detail-breadcrumb', text: /#{Regexp.escape(words[3])}/
      end
    end

    test 'invalid reply displays localized validation errors without new messages' do
      conversation = Conversation.create!(bulletin: bulletins(:first), buyer: users(:two), seller: users(:one))
      sign_in(users(:two))

      {
        ru: 'не может быть пустым',
        en: "can't be blank",
        hy: 'պարտադիր է լրացնել'
      }.each do |locale, expected|
        assert_no_difference 'Message.count' do
          post conversation_messages_path(conversation, locale: locale),
               params: { message: { body: '   ' } }
        end

        assert_response :unprocessable_entity
        assert_select '.alert-danger', text: /#{Regexp.escape(expected)}/
      end
    end

    test 'model messages follow locale for unauthorized sender' do
      conversation = Conversation.create!(bulletin: bulletins(:first), buyer: users(:two), seller: users(:one))
      expected = {
        ru: 'не участвует в переписке',
        en: 'is not a conversation participant',
        hy: 'զրույցի մասնակից չէ'
      }

      expected.each do |locale, message|
        I18n.with_locale(locale) do
          record = Message.new(conversation: conversation, sender: users(:admin), body: 'test')
          assert_not record.valid?
          assert_includes record.errors.full_messages.join, message
        end
      end
    end

    test 'all messaging page, flash and validation translations exist' do
      keys = {
        'pages.conversations.shared' => %w[author buyer user],
        'pages.conversations.message_fields' => %w[not_sent body_label body_placeholder body_hint],
        'pages.conversations.index' => %w[
          page_title eyebrow heading intro back_to_profile list_label unread_count
          empty_heading empty_help browse_catalog
        ],
        'pages.conversations.new' => %w[
          page_title breadcrumb_label catalog eyebrow heading intro form_label send cancel
        ],
        'pages.conversations.show' => %w[
          page_title breadcrumb_label all_conversations eyebrow listing thread_label
          you other_participant reply_form_label reply_heading reply_submit
        ],
        'flash.conversations' => %w[message_sent create_failed self_conversation]
      }

      %i[ru en hy].each do |locale|
        keys.each do |prefix, names|
          names.each do |name|
            assert I18n.exists?("#{prefix}.#{name}", locale), "Missing #{locale}: #{prefix}.#{name}"
          end
        end
        %w[message conversation].each do |name|
          assert I18n.exists?("activerecord.models.#{name}", locale)
        end
        assert I18n.exists?('activerecord.errors.models.message.attributes.sender.not_participant', locale)
        assert I18n.exists?('activerecord.errors.models.conversation.attributes.buyer.cannot_be_author', locale)
        assert I18n.exists?('activerecord.errors.models.conversation.attributes.seller.must_own_listing', locale)
        assert I18n.exists?('activerecord.errors.models.conversation.attributes.bulletin.must_be_published', locale)
        assert I18n.exists?('time.formats.conversation', locale)
      end
    end
  end
end
