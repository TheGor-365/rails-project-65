# frozen_string_literal: true

require 'test_helper'

module Web
  class CatalogSortingTest < ActionDispatch::IntegrationTest
    test 'catalog sorts published bulletins only and exposes active filter indicators' do
      get root_path(sort: 'oldest', q: { title_cont: 'Смартфон' })
      assert_response :success
      assert_select 'select[name="sort"] option[selected="selected"][value="oldest"]'
      assert_select '.cl-active-filters', text: /Смартфон/
      assert_select '.cl-active-filters__clear[href=?]', root_path
      assert_select 'a[href=?]', bulletin_path(bulletins(:first))
      assert_select 'a[href=?]', bulletin_path(bulletins(:second)), count: 0
    end

    test 'invalid sort is ignored and defaults to newest' do
      get root_path(sort: 'title; DROP TABLE bulletins')
      assert_response :success
      assert_select 'select[name="sort"] option[selected="selected"][value="newest"]'
    end

    test 'category chips preserve a selected sorting' do
      get root_path(sort: 'title_asc')
      assert_response :success
      assert_select '.cl-category-strip a[href*="sort=title_asc"]'
    end
  end
end
