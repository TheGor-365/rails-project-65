# frozen_string_literal: true

require 'test_helper'

module Web
  class BulletinsControllerTest < ActionDispatch::IntegrationTest
    test 'guest can view published bulletin' do
      get bulletin_path(bulletins(:first))

      assert_response :success
    end

    test 'guest cannot view draft bulletin' do
      get bulletin_path(bulletins(:second))

      assert_redirected_to root_path
    end

    test 'guest cannot view unpublished states' do
      %w[draft under_moderation rejected archived].each do |state|
        bulletin = Bulletin.create!(
          title: "Hidden #{state}",
          description: "Private test bulletin",
          category: categories(:one),
          user: users(:admin),
          state: state
        )

        get bulletin_path(bulletin)
        assert_redirected_to root_path
      end
    end

    test 'owner can view own unpublished states' do
      owner = User.create!(
        name: 'Security Test Owner',
        email: 'security-owner@example.test'
      )
      sign_in(owner)

      %w[draft under_moderation rejected archived].each do |state|
        bulletin = Bulletin.create!(
          title: "Own #{state}",
          description: "Owner-only content",
          category: categories(:one),
          user: owner,
          state: state
        )

        get bulletin_path(bulletin)
        assert_response :success
      end
    end

    test 'another authenticated user cannot view unpublished states' do
      stranger = User.create!(
        name: 'Security Test Stranger',
        email: 'security-stranger@example.test'
      )
      sign_in(stranger)

      %w[draft under_moderation rejected archived].each do |state|
        bulletin = Bulletin.create!(
          title: "Private #{state}",
          description: "Not for strangers",
          category: categories(:one),
          user: users(:admin),
          state: state
        )

        get bulletin_path(bulletin)
        assert_redirected_to root_path
      end
    end
  end
end
