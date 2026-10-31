# frozen_string_literal: true

require 'test_helper'

module Web
  class ProfileI18nTest < ActionDispatch::IntegrationTest
    test 'profile headings, category options, statuses and actions are localized' do
      sign_in(users(:one))

      {
        ru: { heading: 'Мои объявления', category: 'Электроника', status: 'Опубликовано', action: 'Редактировать' },
        en: { heading: 'My listings', category: 'Electronics', status: 'Published', action: 'Edit' },
        hy: { heading: 'Իմ հայտարարությունները', category: 'Էլեկտրոնիկա',
              status: 'Հրապարակված', action: 'Խմբագրել' }
      }.each do |locale, expected|
        get profile_path(locale: locale)

        assert_response :success
        assert_select "html[lang='#{locale}']"
        assert_select 'h2', text: expected.fetch(:heading)
        assert_select '.cl-metric', count: 3
        assert_select '.cl-status--published', text: expected.fetch(:status)
        assert_select "select[name='q[category_id_eq]'] option", text: expected.fetch(:category)
        assert_select "select[name='q[state_eq]'] option[value='published']", text: expected.fetch(:status)
        assert_select '.cl-management-table td', text: expected.fetch(:category)
        assert_select 'a.btn', text: expected.fetch(:action)
        assert_select 'title', text: /#{Regexp.escape(expected.fetch(:heading))}/
      end
    end

    test 'language selection retains profile status and category filters' do
      sign_in(users(:one))

      get profile_path(locale: 'hy', q: {
        state_eq: 'published', category_id_eq: categories(:one).id
      })

      assert_response :success
      assert_select "select[name='q[state_eq]'] option[value='published'][selected='selected']"
      assert_select "select[name='q[category_id_eq]'] option[value='#{categories(:one).id}'][selected='selected']"
      assert_select '.cl-status--published', text: 'Հրապարակված'
      assert_select '.cl-locale-option[lang="en"][href*="state_eq"]'
      assert_select '.cl-locale-option[lang="en"][href*="category_id_eq"]'
    end

    test 'moderation and archive buttons have localized confirmation text' do
      sign_in(users(:one))
      draft = Bulletin.create!(
        title: 'Draft for profile locale', description: 'Translation verification',
        user: users(:one), category: categories(:one), state: 'draft'
      )

      {
        ru: [ 'Отправить объявление на модерацию?', 'Отправить в архив?' ],
        en: [ 'Submit this listing for review?', 'Move this listing to the archive?' ],
        hy: [ 'Ուղարկե՞լ հայտարարությունը ստուգման։', 'Տեղափոխե՞լ հայտարարությունն արխիվ։' ]
      }.each do |locale, labels|
        get profile_path(locale: locale)

        assert_response :success
        assert_select "tr", text: /#{Regexp.escape(draft.title)}/ do
          assert_select "button[data-turbo-confirm='#{labels.first}']"
          assert_select "button[data-turbo-confirm='#{labels.last}']"
        end
      end
    end

    test 'status labels and profile page keys exist in all locales' do
      profile_keys = %w[
        page_title eyebrow heading lead messages favorites create_listing
        metrics_label total_listings filters_label search_placeholder search_label
        all_categories category_label all_statuses status_label search_action
        reset_action list_label list_heading filtered_count table_listing
        table_actions added edit_action submit_moderation confirm_moderation
        archive_action confirm_archive empty_heading empty_help clear_filters
      ]
      status_keys = %w[draft under_moderation published rejected archived]

      %i[ru en hy].each do |locale|
        profile_keys.each do |key|
          assert I18n.exists?("pages.profiles.show.#{key}", locale), "Missing #{locale}.#{key}"
        end
        status_keys.each do |key|
          assert I18n.exists?("shared.bulletin_states.#{key}", locale), "Missing #{locale}.#{key}"
        end
      end
    end
  end
end
