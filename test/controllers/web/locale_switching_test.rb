# frozen_string_literal: true

require 'test_helper'

class LocaleSwitchingTest < ActionDispatch::IntegrationTest
  test 'defaults to Russian without changing existing routes' do
    get root_path

    assert_response :success
    assert_select 'html[lang="ru"]'
    assert_equal '/', root_path
  end

  test 'English persists across requests and appears in generated links' do
    get root_path(locale: 'en')

    assert_response :success
    assert_select 'html[lang="en"]'
    assert_select 'a.nav-link[href*="locale=en"]'

    get bulletins_path

    assert_response :success
    assert_select 'html[lang="en"]'
  end

  test 'Armenian can be selected and changed back to Russian' do
    get root_path(locale: 'hy')
    assert_response :success
    assert_select 'html[lang="hy"]'

    get root_path(locale: 'ru')
    assert_response :success
    assert_select 'html[lang="ru"]'
  end

  test 'rejects unsupported and structured locale values without raising' do
    get root_path(locale: 'unknown')
    assert_response :success
    assert_select 'html[lang="ru"]'

    get root_path(locale: ['hy'])
    assert_response :success
    assert_select 'html[lang="ru"]'
  end

  test 'core flash and authorization keys exist in each supported locale' do
    keys = %w[
      app.errors.not_authorized profiles.login_required
      flash.auth.sign_in flash.auth.github_login_success
      flash.auth.github_login_fail flash.auth.logged_out
      flash.admin.bulletins.published flash.admin.bulletins.update_failed
      flash.admin.categories.created flash.bulletins.created_draft
      flash.bulletins.sent_to_moderation
    ]

    %i[ru en hy].each do |locale|
      keys.each { |key| assert I18n.exists?(key, locale), "Missing #{'#{'}locale#{'}'} translation #{'#{'}key#{'}'}" }
    end
  end
end
