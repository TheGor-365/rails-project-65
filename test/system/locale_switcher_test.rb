# frozen_string_literal: true

require 'application_system_test_case'

class LocaleSwitcherTest < ApplicationSystemTestCase
  test 'flag dropdown changes locale at mobile width without horizontal overflow' do
    page.driver.browser.manage.window.resize_to(390, 844)
    visit root_path

    assert_selector 'html[lang="ru"]', visible: :all
    assert_selector '#classifiedsLocaleToggle', count: 1
    assert page.evaluate_script('document.documentElement.scrollWidth <= window.innerWidth')

    find('#classifiedsLocaleToggle').click
    assert_selector '.cl-locale-menu.show'
    find('.cl-locale-option[lang="en"]').click
    assert_selector 'html[lang="en"]', visible: :all
    assert_selector '#classifiedsLocaleToggle[aria-label="Choose language"]'
    assert page.evaluate_script('document.documentElement.scrollWidth <= window.innerWidth')

    find('#classifiedsLocaleToggle').click
    find('.cl-locale-option[lang="hy"]').click
    assert_selector 'html[lang="hy"]', visible: :all
    assert_selector '#classifiedsLocaleToggle[aria-label="Ընտրել լեզուն"]'
    assert page.evaluate_script('document.documentElement.scrollWidth <= window.innerWidth')

    visit root_path
    assert_selector 'html[lang="hy"]', visible: :all
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end
end
