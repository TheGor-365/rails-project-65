# frozen_string_literal: true

require 'test_helper'

class ServicePageAssetsTest < ActiveSupport::TestCase
  test 'standard error pages use branded layout and localized messages' do
    %w[404 422 500 503].each do |status|
      html = Rails.root.join('public', "#{status}.html").read
      assert_includes html, '<html lang="ru">'
      assert_includes html, 'Classifieds'
      assert_includes html, 'href="/errors.css"'
      assert_includes html, 'href="/"'
      assert_includes html, "class=\"error-code\""
    end
  end

  test 'favicon and error CSS exist independently of Rails asset compilation' do
    assert Rails.root.join('public/icon.svg').file?
    assert Rails.root.join('public/icon.png').file?
    assert Rails.root.join('public/favicon.ico').file?
    assert Rails.root.join('public/errors.css').file?
    assert Rails.root.join('public/error-theme.js').file?
  end
end
