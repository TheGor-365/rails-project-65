# frozen_string_literal: true

require 'test_helper'

class SharedLocaleUiTest < ActionDispatch::IntegrationTest
  test 'language selector is available in the header for each locale' do
    %w[ru en hy].each do |locale|
      get root_path(locale: locale)

      assert_response :success
      assert_select "html[lang='#{locale}']"
      assert_select "button#classifiedsLocaleToggle[data-bs-toggle='dropdown']", count: 1
      assert_select '.cl-locale-menu .cl-locale-option', count: 3
      assert_select ".cl-locale-option[lang='#{locale}'][aria-current='page']", count: 1
      assert_select "a.cl-locale-option[lang='ru'][href*='locale=ru']", count: 1
      assert_select "a.cl-locale-option[lang='en'][href*='locale=en']", count: 1
      assert_select "a.cl-locale-option[lang='hy'][href*='locale=hy']", count: 1
      assert_select 'button[data-controller="theme"][data-theme-enable-light-label-value]', count: 1
      assert_select 'button[data-controller="theme"][data-theme-enable-dark-label-value]', count: 1
    end
  end

  test 'locale selector preserves current path and filters' do
    get root_path(locale: 'en', sort: 'oldest', q: { title_cont: 'phone' })
    assert_response :success

    assert_select "a.cl-locale-option[lang='hy'][href*='sort=oldest']"
    assert_select "a.cl-locale-option[lang='hy'][href*='title_cont']"
    assert_select "a.cl-locale-option[lang='hy'][data-turbo='false']", count: 1
  end

  test 'shared labels, page title and accessible navigation are translated' do
    {
      'ru' => [ 'Главная', 'Объявления', 'Выбрать язык' ],
      'en' => [ 'Home', 'Listings', 'Choose language' ],
      'hy' => [ 'Գլխավոր', 'Հայտարարություններ', 'Ընտրել լեզուն' ]
    }.each do |locale, values|
      get root_path(locale: locale)

      assert_response :success
      assert_select 'a.cl-nav-link', text: values[0]
      assert_select 'title', text: /#{Regexp.escape(values[1])}/
      assert_select '#classifiedsLocaleToggle', attributes: { 'aria-label' => values[2] }
    end
  end

  test 'selection survives GitHub login and logout without preserving old auth state' do
    get root_path(locale: 'hy')
    sign_in(users(:admin))

    assert_redirected_to root_path(locale: 'hy')
    follow_redirect!
    assert_select "html[lang='hy']"
    assert_select "a.cl-nav-link", text: 'Գլխավոր'

    delete signout_path
    assert_redirected_to root_path(locale: 'hy')
    follow_redirect!
    assert_select "html[lang='hy']"
    assert_select 'form button', text: 'Մուտք գործել GitHub-ով'
  end

  test 'all shared UI messages have translations in every supported language' do
    keys = %w[
      shared.header.main_navigation shared.header.open_menu shared.header.home
      shared.header.admin shared.header.messages shared.header.profile
      shared.header.sign_out shared.header.sign_in_github
      shared.header.select_language shared.header.current_language
      shared.header.unread_messages shared.theme.enable_dark
      shared.theme.enable_light shared.footer.credit
      shared.meta.default_title shared.pagination.navigation_label
      views.pagination.first views.pagination.last
      views.pagination.previous views.pagination.next views.pagination.truncate
    ]

    %i[ru en hy].each do |locale|
      keys.each do |key|
        assert I18n.exists?(key, locale), "Missing #{locale}.#{key}"
      end
    end
  end
end
