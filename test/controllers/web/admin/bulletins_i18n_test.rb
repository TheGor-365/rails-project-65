# frozen_string_literal: true

require 'test_helper'

module Web
  module Admin
    class BulletinsI18nTest < ActionDispatch::IntegrationTest
      test 'moderation table and filters use selected locale without changing listing content' do
        sign_in(users(:admin))
        bulletin = bulletins(:second)
        bulletin.update!(state: 'under_moderation')

        {
          ru: [ 'Модерация объявлений', 'На модерации', 'Одежда', 'Опубликовать' ],
          en: [ 'Listing moderation', 'Under review', 'Clothing', 'Publish' ],
          hy: [ 'Հայտարարությունների ստուգում', 'Ստուգման փուլում', 'Հագուստ', 'Հրապարակել' ]
        }.each do |locale, words|
          get admin_bulletins_path(locale: locale, q: { state_eq: 'under_moderation' })

          assert_response :success
          assert_select "html[lang='#{locale}']"
          assert_select 'h2', text: words[0]
          assert_select "select[name='q[state_eq]'] option[value='under_moderation'][selected='selected']",
                        text: words[1]
          assert_select "select[name='q[category_id_eq]'] option[value='#{categories(:two).id}']",
                        text: words[2]
          assert_select '.cl-status--under_moderation', text: words[1]
          assert_select 'button', text: words[3]
          assert_select '.cl-management-link', text: bulletin.title
          assert_select '.cl-locale-option[lang="en"][href*="state_eq"]'
        end
      end

      test 'reject and archive confirm messages are translated' do
        sign_in(users(:admin))
        bulletin = bulletins(:second)
        bulletin.update!(state: 'under_moderation')

        {
          ru: [ 'Отклонить объявление?', 'Отправить объявление в архив?' ],
          en: [ 'Reject this listing?', 'Move this listing to the archive?' ],
          hy: [ 'Մերժե՞լ այս հայտարարությունը։', 'Արխիվացնե՞լ այս հայտարարությունը։' ]
        }.each do |locale, words|
          get admin_bulletins_path(locale: locale)

          assert_response :success
          assert_select "tr", text: /#{Regexp.escape(bulletin.title)}/ do
            assert_select "button[data-turbo-confirm='#{words.first}']"
            assert_select "button[data-turbo-confirm='#{words.last}']"
          end
        end
      end

      test 'show and edit labels localize without changing bulletin title or language' do
        sign_in(users(:admin))
        bulletin = bulletins(:first)
        bulletin.update!(language: 'hy')

        {
          ru: [ 'Описание объявления', 'Редактирование объявления' ],
          en: [ 'Listing description', 'Edit listing' ],
          hy: [ 'Հայտարարության նկարագրություն', 'Խմբագրել հայտարարությունը' ]
        }.each do |locale, words|
          get admin_bulletin_path(bulletin, locale: locale)
          assert_response :success
          assert_select 'h2', text: bulletin.title
          assert_select 'h3', text: words[0]

          get edit_admin_bulletin_path(bulletin, locale: locale)
          assert_response :success
          assert_select 'h2', text: words[1]
          assert_select 'select[name="bulletin[language]"]', count: 0
        end

        assert_equal 'hy', bulletin.reload.language
      end

      test 'all admin bulletin translation keys exist in three locales' do
        index = %w[
          page_title eyebrow heading lead categories metrics_label total_listings
          waiting_review filters_label search_placeholder search_label all_categories
          category_label all_statuses status_label author_email search_action
          reset_action results_label queue_heading filtered_count column_listing
          column_author column_actions added publish_action reject_action
          archive_action confirm_reject confirm_archive empty_heading empty_help clear_filters
        ]
        show = %w[
          page_title eyebrow lead edit_action back_action category author
          not_specified description_heading
        ]
        edit = %w[page_title eyebrow heading lead]

        %i[ru en hy].each do |locale|
          { index: index, show: show, edit: edit }.each do |page, keys|
            keys.each do |key|
              assert I18n.exists?("pages.admin.bulletins.#{page}.#{key}", locale),
                     "Missing #{locale}.admin.bulletins.#{page}.#{key}"
            end
          end
        end
      end
    end
  end
end
