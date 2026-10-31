# frozen_string_literal: true

require 'application_system_test_case'

class GuestCatalogTest < ApplicationSystemTestCase
  test 'guest sees published bulletins but not drafts' do
    visit root_path

    assert_selector 'h2', text: 'Объявления'
    assert_text 'Смартфон в хорошем состоянии'
    assert_no_text 'Куртка зимняя'
  end

  test 'guest can open a published bulletin from the catalog' do
    visit root_path
    click_link 'Смартфон в хорошем состоянии'

    assert_current_path bulletin_path(bulletins(:first))
    assert_selector 'h2', text: 'Смартфон в хорошем состоянии'
    assert_text 'Полный комплект. Без сколов и царапин.'
  end

  test 'guest cannot view draft details through a direct URL' do
    visit bulletin_path(bulletins(:second))

    assert_current_path root_path
    assert_no_text 'Размер L. Тёплая, почти новая.'
  end

  test 'guest can search the catalog by bulletin title' do
    visit root_path
    fill_in 'q_title_cont', with: 'Смартфон'
    click_button 'Искать'

    assert_text 'Смартфон в хорошем состоянии'
    assert_no_text 'Куртка зимняя'
  end
end
