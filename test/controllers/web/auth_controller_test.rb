# frozen_string_literal: true

require 'test_helper'

module Web
  class AuthControllerTest < ActionDispatch::IntegrationTest
    test 'check github auth' do
      post auth_request_path('github')
      assert_response :redirect
    end

    test 'create' do
      auth_hash = {
        provider: 'github',
        uid: '12345',
        info: {
          email: Faker::Internet.email,
          name: Faker::Name.first_name
        }
      }

      OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash::InfoHash.new(auth_hash)

      get callback_auth_url('github')
      assert_response :redirect

      user = User.find_by(email: auth_hash[:info][:email].downcase)

      assert user
      assert signed_in?
    end

    test 'github identity survives email change' do
      uid = 'stable-github-uid-98765'

      OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
        provider: 'github',
        uid: uid,
        info: {
          email: 'oauth-initial@example.test',
          name: 'OAuth Test User'
        }
      )

      get callback_auth_url('github')
      original_user = User.find_by!(email: 'oauth-initial@example.test')

      delete signout_path

      OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
        provider: 'github',
        uid: uid,
        info: {
          email: 'oauth-updated@example.test',
          name: 'OAuth Test User'
        }
      )

      assert_no_difference('User.count') do
        get callback_auth_url('github')
      end

      assert_equal original_user.id, session[:user_id]
    end

    test 'unlinked github identity cannot access existing admin' do
      admin = users(:admin)

      OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
        provider: 'github',
        uid: 'unlinked-github-identity',
        info: {
          email: admin.email,
          name: 'Unknown GitHub User'
        }
      )

      assert_no_difference('OauthIdentity.count') do
        get callback_auth_url('github')
      end

      assert_not_equal admin.id, session[:user_id]
    end

    test 'link requires verified oauth session' do
      get github_link_form_path
      assert_redirected_to root_path

      post prepare_github_link_path
      assert_redirected_to root_path
      assert_nil session[:oauth_link_user_id]

      sign_in(users(:admin))
      assert_equal users(:admin).id, session[:oauth_verified_user_id]

      get github_link_form_path
      assert_response :success

      post prepare_github_link_path
      assert_response :success
      assert_equal users(:admin).id, session[:oauth_link_user_id]
    end

    test 'signout clears verified oauth session' do
      user = users(:admin)
      sign_in(user)

      assert_equal user.id, session[:user_id]
      assert_equal user.id, session[:oauth_verified_user_id]

      delete signout_path

      assert_redirected_to root_path
      assert_nil session[:user_id]
      assert_nil session[:oauth_verified_user_id]
    end
  end
end
