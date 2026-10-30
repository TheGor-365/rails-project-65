# frozen_string_literal: true

require 'test_helper'

module Web
  class BulletinFormLayoutTest < ActionDispatch::IntegrationTest
    test 'new bulletin uses editor layout while preserving multipart upload and submit route' do
      sign_in(users(:one))
      get new_bulletin_path

      assert_response :success
      assert_select 'form[action=?]', bulletins_path
      assert_select 'input[name="bulletin[image]"][accept=?]', 'image/jpeg,image/png,image/webp'
      assert_select 'div.cl-editor-grid'
      assert_select 'button[data-controller="theme"]', count: 1
    end

    test 'owner edit keeps current item and its update route' do
      sign_in(users(:one))
      get edit_bulletin_path(bulletins(:first))

      assert_response :success
      assert_select 'form[action=?]', bulletin_path(bulletins(:first))
      assert_select 'input[name="bulletin[title]"]'
    end
  end
end
