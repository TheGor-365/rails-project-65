# frozen_string_literal: true

require 'test_helper'

class OauthIdentityTest < ActiveSupport::TestCase
  test 'requires provider and uid' do
    identity = OauthIdentity.new(user: users(:one))

    assert_not identity.valid?
    assert_includes identity.errors.attribute_names, :provider
    assert_includes identity.errors.attribute_names, :uid
  end

  test 'rejects duplicate provider and uid' do
    OauthIdentity.create!(
      user: users(:one),
      provider: 'github',
      uid: '12345'
    )

    duplicate = OauthIdentity.new(
      user: users(:two),
      provider: 'github',
      uid: '12345'
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :uid
  end

  test 'allows the same uid for different providers' do
    users(:one).oauth_identities.create!(
      provider: 'github',
      uid: '12345'
    )

    identity = users(:two).oauth_identities.create!(
      provider: 'google_oauth2',
      uid: '12345'
    )

    assert_predicate identity, :persisted?
  end
end
