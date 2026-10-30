# frozen_string_literal: true

require 'application_system_test_case'

class MarketplaceLayoutTest < ApplicationSystemTestCase
  test 'catalog previews have identical media proportions' do
    bulletins(:second).update!(state: 'published')
    visit root_path

    assert_selector '.cl-listing-card', count: 2

    sizes = page.evaluate_script(
      "Array.from(document.querySelectorAll('.cl-listing-card__media')).map(el => Math.round(el.getBoundingClientRect().height))"
    )
    assert_equal 2, sizes.size
    assert_equal sizes.first, sizes.last
  end

  test 'category chips filter listings and details use shared layout' do
    visit root_path
    within('.cl-category-strip') { click_link 'Электроника' }

    assert_text 'Смартфон в хорошем состоянии'
    click_link 'Смартфон в хорошем состоянии'

    assert_selector '.cl-detail-grid'
    assert_text 'Автор'
    assert_text 'Дата добавления'
    assert_link 'Другие в этой категории'
  end
end
