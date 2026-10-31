# frozen_string_literal: true

require 'test_helper'

module Web
  module Admin
    class CategoriesI18nTest < ActionDispatch::IntegrationTest
      test 'categories index translates actions and preserves raw database names' do
        sign_in(users(:admin))
        {
          ru: [ 'Категории', 'Создать категорию', 'Удалить категорию?' ],
          en: [ 'Categories', 'Create category', 'Delete this category?' ],
          hy: [ 'Կատեգորիաներ', 'Ստեղծել կատեգորիա', 'Ջնջե՞լ այս կատեգորիան։' ]
        }.each do |locale, words|
          get admin_categories_path(locale: locale)

          assert_response :success
          assert_select "html[lang='#{locale}']"
          assert_select 'h2', text: words.first
          assert_select "form input[type='submit'][value=?]", words.second
          assert_select "a[data-turbo-confirm='#{words.last}']", minimum: 1
          assert_select '.cl-management-list-item', text: /#{Regexp.escape(categories(:one).name)}/
        end
      end

      test 'new and edit forms translate field names while preserving category value' do
        sign_in(users(:admin))
        {
          ru: [ 'Название', 'Редактировать категорию' ],
          en: [ 'Name', 'Edit category' ],
          hy: [ 'Անվանում', 'Խմբագրել կատեգորիան' ]
        }.each do |locale, words|
          get new_admin_category_path(locale: locale)

          assert_response :success
          assert_select 'label[for="category_name"]', text: words.first

          get edit_admin_category_path(categories(:one), locale: locale)
          assert_response :success
          assert_select 'h2', text: words.last
          assert_select 'input[name="category[name]"][value=?]', categories(:one).name
        end
      end

      test 'category validation messages use selected locale' do
        sign_in(users(:admin))

        {
          ru: 'Название',
          en: 'Name',
          hy: 'Անվանում'
        }.each do |locale, label|
          post admin_categories_path(locale: locale), params: { category: { name: '' } }

          assert_response :unprocessable_entity
          assert_select '.alert-danger', text: /#{Regexp.escape(label)}/
        end
      end

      test 'all category administrative keys exist in RU EN HY' do
        index = %w[
          page_title eyebrow heading lead to_moderation create_section new_heading
          create_hint create_action list_section list_heading total_count edit_action
          delete_action confirm_delete empty_heading empty_help
        ]

        %i[ru en hy].each do |locale|
          index.each do |key|
            assert I18n.exists?("pages.admin.categories.index.#{key}", locale)
          end
          %w[name_label name_placeholder save].each do |key|
            assert I18n.exists?("pages.admin.categories.form.#{key}", locale)
          end
          %w[new edit].each do |page|
            %w[page_title eyebrow heading lead back submit].each do |key|
              assert I18n.exists?("pages.admin.categories.#{page}.#{key}", locale)
            end
          end
          assert I18n.exists?('activerecord.attributes.category.name', locale)
        end
      end
    end
  end
end
