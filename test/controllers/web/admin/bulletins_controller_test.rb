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

      test 'admin detail has edit link' do
        sign_in(users(:admin))
        bulletin = bulletins(:second)

        get admin_bulletin_path(bulletin)

        assert_response :success
        assert_select 'a[href=?]', edit_admin_bulletin_path(bulletin)
      end

      test 'admin edit form uses admin update route' do
        sign_in(users(:admin))
        bulletin = bulletins(:second)

        get edit_admin_bulletin_path(bulletin)

        assert_response :success
        assert_select 'form[action=?]', admin_bulletin_path(bulletin)
      end

      test 'admin can update another users bulletin' do
        sign_in(users(:admin))
        bulletin = bulletins(:second)

        patch admin_bulletin_path(bulletin),
              params: { bulletin: { title: 'Updated by admin' } }

        assert_redirected_to admin_bulletins_path
        assert_equal 'Updated by admin', bulletin.reload.title
      end

      test 'regular user cannot update another users bulletin' do
        sign_in(users(:one))
        bulletin = bulletins(:second)

        assert_no_changes -> { bulletin.reload.title } do
          patch admin_bulletin_path(bulletin),
                params: { bulletin: { title: 'Unauthorized update' } }
        end

        assert_redirected_to root_path
      end

      test 'guest cannot update bulletin through admin' do
        bulletin = bulletins(:second)

        assert_no_changes -> { bulletin.reload.title } do
          patch admin_bulletin_path(bulletin),
                params: { bulletin: { title: 'Guest update' } }
        end

        assert_redirected_to root_path
      end
    end
  end
end
