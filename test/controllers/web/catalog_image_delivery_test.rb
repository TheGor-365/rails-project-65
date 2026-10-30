# frozen_string_literal: true

require 'test_helper'
require 'base64'
require 'stringio'

module Web
  class CatalogImageDeliveryTest < ActionDispatch::IntegrationTest
    PNG = Base64.strict_decode64(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/54cAAAAASUVORK5CYII='
    )

    test 'catalog serves original attached images without runtime variants' do
      bulletins(:first).image.attach(
        io: StringIO.new(PNG), filename: 'listing.png', content_type: 'image/png'
      )

      get root_path

      assert_response :success
      assert_select '.cl-listing-card__media img.cl-listing-card__image', count: 1
      assert_select '.cl-listing-card__media img[src*="/rails/active_storage/blobs/"]', count: 1
      assert_select '.cl-listing-card__media img[src*="/rails/active_storage/representations/"]', count: 0
    end

    test 'catalog keeps placeholder for bulletin without an attached image' do
      get root_path

      assert_response :success
      assert_select '.cl-listing-card__placeholder', count: 1
    end
  end
end
