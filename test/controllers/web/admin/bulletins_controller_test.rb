# frozen_string_literal: true

require 'test_helper'

module Web
  module Admin
    class BulletinsControllerTest < ActionDispatch::IntegrationTest
      test 'admin can view published and draft bulletins' do
        sign_in(users(:admin))

        [bulletins(:first), bulletins(:second)].each do |bulletin|
          get admin_bulletin_path(bulletin)

          assert_response :success
          assert_select 'h2', text: bulletin.title
        end
      end

      test 'guest cannot access admin bulletin' do
        get admin_bulletin_path(bulletins(:second))

        assert_redirected_to root_path
      end

      test 'regular user cannot access admin bulletin' do
        sign_in(users(:one))

        get admin_bulletin_path(bulletins(:second))

        assert_redirected_to root_path
      end
    end
  end
end
