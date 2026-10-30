# frozen_string_literal: true

require 'application_system_test_case'

class GuestCatalogTest < ApplicationSystemTestCase
  test 'guest sees published bulletins but not drafts' do
    visit root_path

    assert_selector 'h2', text: 'Объявления'
    assert_text 'Смартфон в хорошем состоянии'
    assert_no_text 'Куртка зимняя'
  end
end
