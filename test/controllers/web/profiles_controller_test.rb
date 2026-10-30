# frozen_string_literal: true

require 'test_helper'

module Web
  class ProfilesControllerTest < ActionDispatch::IntegrationTest
    test 'member sees own listing summary and localized states' do
      sign_in(users(:one))

      get profile_path

      assert_response :success
      assert_select 'h2', text: 'Мои объявления'
      assert_select '.cl-metric', count: 3
      assert_select '.cl-status--published', text: /Опубликовано/
      assert_select 'a[href=?]', edit_bulletin_path(bulletins(:first))
    end

    test 'guest cannot access profile' do
      get profile_path

      assert_redirected_to root_path
    end
  end
end
