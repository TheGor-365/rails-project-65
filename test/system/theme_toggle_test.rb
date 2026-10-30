# frozen_string_literal: true

require 'application_system_test_case'

class ThemeToggleTest < ApplicationSystemTestCase
  test 'one icon toggles color mode and persists across navigation and reload' do
    visit root_path
    page.execute_script("localStorage.setItem('classifieds:theme', 'light')")
    visit root_path

    assert_selector 'html[data-bs-theme="light"]', visible: :all
    assert_selector 'button[data-controller="theme"]', count: 1
    assert_selector 'button[data-controller="theme"] i.bi-moon-stars', count: 1

    light_background = page.evaluate_script('getComputedStyle(document.body).backgroundColor')
    find('button[data-controller="theme"]').click

    assert_selector 'html[data-bs-theme="dark"]', visible: :all
    assert_selector 'button[data-controller="theme"] i.bi-sun', count: 1
    assert_equal 'dark', page.evaluate_script("localStorage.getItem('classifieds:theme')")
    assert_not_equal light_background, page.evaluate_script('getComputedStyle(document.body).backgroundColor')

    click_link 'Смартфон в хорошем состоянии'
    assert_selector 'html[data-bs-theme="dark"]', visible: :all
    assert_selector 'button[data-controller="theme"] i.bi-sun', count: 1
    page.refresh
    assert_selector 'html[data-bs-theme="dark"]', visible: :all

    find('button[data-controller="theme"]').click
    assert_selector 'html[data-bs-theme="light"]', visible: :all
    assert_selector 'button[data-controller="theme"] i.bi-moon-stars', count: 1
  end

  test 'invalid stored preference falls back to valid system color mode' do
    visit root_path
    page.execute_script("localStorage.setItem('classifieds:theme', 'invalid')")
    visit root_path

    assert_includes %w[light dark], page.evaluate_script("document.documentElement.getAttribute('data-bs-theme')")
    assert_selector 'button[data-controller="theme"]', count: 1
  end
end
