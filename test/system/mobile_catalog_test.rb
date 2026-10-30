# frozen_string_literal: true

require 'application_system_test_case'

class MobileCatalogTest < ApplicationSystemTestCase
  test 'catalog search remains usable without horizontal page overflow at mobile width' do
    page.driver.browser.manage.window.resize_to(390, 844)
    visit root_path

    assert_selector 'input[name="q[title_cont]"]'
    assert_selector 'select[name="q[category_id_eq]"]'
    assert_button 'Искать'
    assert page.evaluate_script('document.documentElement.scrollWidth <= window.innerWidth')
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end
end
