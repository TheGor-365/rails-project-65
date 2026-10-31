# frozen_string_literal: true

require 'test_helper'

module Web
  module Admin
    class CategoriesControllerTest < ActionDispatch::IntegrationTest
      test 'admin categories index renders category form and existing categories' do
        sign_in(users(:admin))

        get admin_categories_path

        assert_response :success
        assert_select 'form[action=?]', admin_categories_path
        assert_select 'input[name="category[name]"]'
        assert_select '.list-group-item', minimum: 1
      end

      test 'guest and regular member cannot view categories administration' do
        get admin_categories_path
        assert_redirected_to root_path

        sign_in(users(:one))
        get admin_categories_path
        assert_redirected_to root_path
      end
    end
  end
end
