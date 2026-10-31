# frozen_string_literal: true

require 'test_helper'
module Web
  class FavoritesControllerTest < ActionDispatch::IntegrationTest
    test 'guest cannot list or favorite bulletins' do
      get favorites_path
      assert_redirected_to root_path
      post bulletin_favorite_path(bulletins(:first))
      assert_redirected_to root_path
      assert_equal 0, Favorite.count
    end

    test 'user can add only published bulletin once and remove it' do
      sign_in(users(:one))
      2.times { post bulletin_favorite_path(bulletins(:first)) }
      assert_redirected_to bulletin_path(bulletins(:first))
      assert_equal 1, Favorite.where(user: users(:one), bulletin: bulletins(:first)).count
      post bulletin_favorite_path(bulletins(:second))
      assert_response :not_found
      get favorites_path
      assert_response :success
      assert_select 'h2', text: 'Избранные объявления'
      assert_select 'a[href=?]', bulletin_path(bulletins(:first))
      delete bulletin_favorite_path(bulletins(:first))
      assert_redirected_to bulletin_path(bulletins(:first))
      assert_equal 0, Favorite.count
    end

    test 'favorites belong only to the current user' do
      Favorite.create!(user: users(:two), bulletin: bulletins(:first))
      sign_in(users(:one))
      get favorites_path
      assert_response :success
      assert_select 'h3', text: 'Здесь пока нет объявлений'
    end
  end
end
