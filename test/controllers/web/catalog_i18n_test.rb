# frozen_string_literal: true

require 'test_helper'

module Web
  class CatalogI18nTest < ActionDispatch::IntegrationTest
    test 'catalog has consistent Russian, English and Armenian labels and canonical categories' do
      {
        'ru' => { heading: 'Объявления', search: 'Искать', category: 'Электроника' },
        'en' => { heading: 'Listings', search: 'Search', category: 'Electronics' },
        'hy' => { heading: 'Հայտարարություններ', search: 'Որոնել', category: 'Էլեկտրոնիկա' }
      }.each do |locale, expected|
        get root_path(locale: locale)

        assert_response :success
        assert_select "html[lang='#{locale}']"
        assert_select 'h2', text: expected.fetch(:heading)
        assert_select "input[type='submit'][value='#{expected.fetch(:search)}']"
        assert_select '.cl-listing-card__category', text: /#{Regexp.escape(expected.fetch(:category))}/
        assert_select 'select[name="q[category_id_eq]"] option', text: expected.fetch(:category)
      end
    end

    test 'filtered and empty-state translations keep search criteria' do
      get root_path(locale: 'en', q: { title_cont: 'not-such-a-listing' }, sort: 'oldest')

      assert_response :success
      assert_select '.cl-empty-state h3', text: 'No listings found'
      assert_select '.cl-active-filters', text: /not-such-a-listing/
      assert_select 'select[name="sort"] option[selected="selected"][value="oldest"]'
      assert_select '.cl-category-strip a[href*="sort=oldest"]'
      assert_select '.cl-active-filters__clear[href*="locale=en"]'
    end

    test 'all canonical category translations and catalog copy exist' do
      catalog = %w[
        eyebrow heading found_count create filter_bar search_placeholder search_label
        all_categories category_label sort_label sort.newest sort.oldest
        sort.title_asc sort.title_desc submit reset category_quick_select all
        active_filters applied sort_applied clear_all empty_heading empty_help
        all_listings
      ]
      card = %w[open_listing no_photo added]
      categories = %w[clothing services electronics]

      %i[ru en hy].each do |locale|
        (catalog.map { |key| "pages.catalog.#{key}" } +
         card.map { |key| "pages.bulletins.card.#{key}" } +
         categories.map { |key| "models.categories.#{key}" }).each do |key|
          assert I18n.exists?(key, locale), "Missing #{locale}.#{key}"
        end
      end
    end
  end
end
