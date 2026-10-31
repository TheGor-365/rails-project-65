# frozen_string_literal: true

require 'test_helper'

module Web
  class AuthI18nTest < ActionDispatch::IntegrationTest
    test 'verified user sees fully localized GitHub link and confirmation pages' do
      sign_in(users(:one))

      {
        ru: [ 'Привязка GitHub', 'Продолжить', 'Подтверждение GitHub', 'Подтвердить через GitHub' ],
        en: [ 'Connect GitHub', 'Continue', 'Verify GitHub account', 'Verify with GitHub' ],
        hy: [ 'Կապակցել GitHub-ը', 'Շարունակել', 'GitHub-ի հաշվի հաստատում', 'Հաստատել GitHub-ի միջոցով' ]
      }.each do |locale, values|
        get github_link_form_path(locale: locale)

        assert_response :success
        assert_select "html[lang='#{locale}']"
        assert_select 'h1', text: values[0]
        assert_select 'form[action=?]', (locale == :ru ? prepare_github_link_path : prepare_github_link_path(locale: locale))
        assert_select 'button', text: values[1]
        assert_select 'title', text: /GitHub/

        post prepare_github_link_path(locale: locale)

        assert_response :success
        assert_equal users(:one).id, session[:oauth_link_user_id]
        assert_select 'h1', text: values[2]
        assert_select 'button', text: values[3]
        assert_select 'form[data-turbo="false"]', count: 1
      end
    end

    test 'unverified session is blocked from GitHub account linking in all languages' do
      %i[ru en hy].each do |locale|
        get github_link_form_path(locale: locale)
        assert_redirected_to(locale == :ru ? root_path : root_path(locale: locale))

        post prepare_github_link_path(locale: locale)
        assert_redirected_to(locale == :ru ? root_path : root_path(locale: locale))
        assert_nil session[:oauth_link_user_id]
      end
    end

    test 'complete locale dictionaries exist for both OAuth pages' do
      %i[ru en hy].each do |locale|
        %w[page_title heading intro].each do |key|
          %w[link_form prepare_link].each do |page|
            assert I18n.exists?("pages.auth.#{page}.#{key}", locale)
          end
        end
        assert I18n.exists?('pages.auth.link_form.continue', locale)
        assert I18n.exists?('pages.auth.prepare_link.confirm', locale)
      end
    end
  end
end
