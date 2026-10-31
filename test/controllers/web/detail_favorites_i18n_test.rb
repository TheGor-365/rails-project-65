# frozen_string_literal: true

require 'test_helper'

module Web
  class DetailFavoritesI18nTest < ActionDispatch::IntegrationTest
    test 'listing detail localizes UI but does not translate user content' do
      {
        ru: { category: 'Электроника', label: 'Дата добавления', breadcrumb: 'Все объявления' },
        en: { category: 'Electronics', label: 'Date added', breadcrumb: 'All listings' },
        hy: { category: 'Էլեկտրոնիկա', label: 'Ավելացման ամսաթիվ', breadcrumb: 'Բոլոր հայտարարությունները' }
      }.each do |locale, expected|
        get bulletin_path(bulletins(:first), locale: locale)

        assert_response :success
        assert_select "html[lang='#{locale}']"
        assert_select 'h2', text: bulletins(:first).title
        assert_select '.cl-detail-sidebar', text: /#{Regexp.escape(expected.fetch(:category))}/
        assert_select '.cl-detail-sidebar', text: /#{Regexp.escape(expected.fetch(:label))}/
        assert_select '.cl-detail-breadcrumb', text: /#{Regexp.escape(expected.fetch(:breadcrumb))}/
        assert_select 'title', text: /#{Regexp.escape(bulletins(:first).title)}/
      end
    end

    test 'favorites page renders empty state and heading for each locale' do
      sign_in(users(:one))

      {
        ru: [ 'Избранные объявления', 'Здесь пока нет объявлений' ],
        en: [ 'Saved listings', 'No saved listings yet' ],
        hy: [ 'Ընտրյալ հայտարարություններ', 'Դեռ պահպանված հայտարարություններ չկան' ]
      }.each do |locale, expected|
        get favorites_path(locale: locale)

        assert_response :success
        assert_select 'h2', text: expected.fetch(0)
        assert_select '.cl-empty-state h3', text: expected.fetch(1)
      end
    end

    test 'adding and removing a favorite shows translated flash and retains selected locale' do
      sign_in(users(:one))
      get root_path(locale: 'en')

      post bulletin_favorite_path(bulletins(:first))
      assert_redirected_to bulletin_path(bulletins(:first), locale: 'en')
      follow_redirect!
      assert_select '.alert', text: /Listing added to your saved items/

      delete bulletin_favorite_path(bulletins(:first))
      assert_redirected_to bulletin_path(bulletins(:first), locale: 'en')
      follow_redirect!
      assert_select '.alert', text: /Listing removed from your saved items/
    end

    test 'all detail and favorites locale keys exist' do
      show = %w[
        page_title breadcrumb_navigation all_listings no_photo gallery_navigation
        gallery_photo gallery_image_alt eyebrow listing_information category
        author created_at in_favorites add_favorite message_author more_in_category
      ]
      favorites = %w[
        page_title eyebrow heading explanation back_to_profile saved_count
        empty_heading empty_help browse_catalog
      ]

      %i[ru en hy].each do |locale|
        (show.map { |key| "pages.bulletins.show.#{key}" } +
         favorites.map { |key| "pages.favorites.index.#{key}" } +
         %w[flash.favorites.added flash.favorites.removed]).each do |key|
          assert I18n.exists?(key, locale), "Missing #{locale}.#{key}"
        end
      end
    end
  end
end
