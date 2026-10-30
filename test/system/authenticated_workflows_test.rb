# frozen_string_literal: true

require 'application_system_test_case'

class AuthenticatedWorkflowsTest < ApplicationSystemTestCase
  test 'github-authenticated member can sign out' do
    sign_in_with_github(users(:one))

    assert_link 'Профиль'
    click_button 'Выйти'

    assert_current_path root_path
    assert_button 'Войти через GitHub'
    assert_no_link 'Профиль'
  end

  test 'regular member cannot access admin moderation' do
    sign_in_with_github(users(:one))
    visit admin_bulletins_path

    assert_current_path root_path
    assert_no_text 'Куртка зимняя'
  end

  test 'admin can publish a pending bulletin in browser' do
    bulletin = bulletins(:second)
    bulletin.update!(state: 'under_moderation')

    sign_in_with_github(users(:admin))
    visit admin_bulletins_path

    within('tr', text: bulletin.title) do
      click_button 'Опубликовать'
    end

    assert_equal 'published', bulletin.reload.state

    visit root_path
    assert_link bulletin.title
  end

  private

  def sign_in_with_github(user)
    uid = "system-github-#{user.id}"
    user.oauth_identities.find_or_create_by!(provider: 'github', uid: uid)

    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: 'github',
      uid: uid,
      info: { email: user.email, name: user.name }
    )

    visit callback_auth_path('github')
    assert_button 'Выйти'
  end
end
