# frozen_string_literal: true

require 'application_system_test_case'

class AppShellTest < ApplicationSystemTestCase
  test 'guest has the same header footer and theme control on catalog and bulletin detail' do
    visit root_path

    assert_selector 'header.cl-site-header .cl-brand', text: 'Classifieds'
    assert_selector 'footer.cl-site-footer', text: 'Hexlet'
    assert_selector 'button[data-controller="theme"]', count: 1

    click_link 'Смартфон в хорошем состоянии'

    assert_selector 'header.cl-site-header .cl-brand', text: 'Classifieds'
    assert_selector 'footer.cl-site-footer', text: 'Hexlet'
    assert_selector 'button[data-controller="theme"]', count: 1
  end

  test 'mobile navigation reveals guest actions without document overflow' do
    page.driver.browser.manage.window.resize_to(390, 844)
    visit root_path

    assert_selector 'button.navbar-toggler', visible: true
    find('button.navbar-toggler').click

    assert_selector '#classifiedsNavigation.show'
    assert_link 'Главная', visible: true
    assert_button 'Войти через GitHub', visible: true
    assert page.evaluate_script('document.documentElement.scrollWidth <= window.innerWidth')
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end
end
