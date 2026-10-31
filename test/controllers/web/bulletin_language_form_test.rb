# frozen_string_literal: true

require 'test_helper'

module Web
  class BulletinLanguageFormTest < ActionDispatch::IntegrationTest
    test 'new listing defaults to current interface locale in all three languages' do
      sign_in(users(:one))

      %w[ru en hy].each do |locale|
        get new_bulletin_path(locale: locale)

        assert_response :success
        assert_select "html[lang='#{locale}']"
        assert_select "select[name='bulletin[language]']", count: 1
        assert_select "select[name='bulletin[language]'] option[value='#{locale}'][selected='selected']"
        assert_select "select[name='bulletin[language]'] option", count: 3
      end
    end

    test 'new listing respects explicitly selected language' do
      sign_in(users(:one))
      get new_bulletin_path(locale: 'en')

      assert_difference 'Bulletin.count', 1 do
        post bulletins_path, params: {
          bulletin: listing_attributes('hy')
        }
      end

      assert_equal 'hy', Bulletin.order(:id).last.language
      assert_redirected_to profile_path(locale: 'en')
    end

    test 'request without language uses current locale, not database fallback' do
      sign_in(users(:one))
      get new_bulletin_path(locale: 'hy')

      attrs = listing_attributes('ru').except(:language)
      assert_difference 'Bulletin.count', 1 do
        post bulletins_path, params: { bulletin: attrs }
      end

      assert_equal 'hy', Bulletin.order(:id).last.language
    end

    test 'invalid language returns localized error and does not create a listing' do
      sign_in(users(:one))
      get new_bulletin_path(locale: 'en')

      assert_no_difference 'Bulletin.count' do
        post bulletins_path, params: {
          bulletin: listing_attributes('unsupported')
        }
      end

      assert_response :unprocessable_entity
      assert_select '.alert-danger', text: /Listing language/
      assert_select '.alert-danger', text: /not a supported value/
    end

    test 'editing a listing never changes its existing language implicitly' do
      bulletin = bulletins(:first)
      bulletin.update!(language: 'hy')
      sign_in(users(:one))

      get edit_bulletin_path(bulletin, locale: 'en')
      assert_response :success
      assert_select "select[name='bulletin[language]'] option[value='hy'][selected='selected']"

      patch bulletin_path(bulletin), params: { bulletin: { title: 'Retitled listing' } }
      assert_redirected_to profile_path(locale: 'en')
      assert_equal 'hy', bulletin.reload.language
    end

    test 'administrator cannot silently replace language via existing update endpoint' do
      bulletin = bulletins(:second)
      bulletin.update!(language: 'hy')
      sign_in(users(:admin))

      get edit_admin_bulletin_path(bulletin, locale: 'en')
      assert_response :success
      assert_select "select[name='bulletin[language]']", count: 0

      patch admin_bulletin_path(bulletin), params: { bulletin: { title: 'Reviewed', language: 'ru' } }
      assert_redirected_to admin_bulletins_path(locale: 'en')
      assert_equal 'hy', bulletin.reload.language
    end

    private

    def listing_attributes(language)
      { title: 'A test listing', description: 'Test information for a listing',
        category_id: categories(:one).id, language: language }
    end
  end
end
