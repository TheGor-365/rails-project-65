# frozen_string_literal: true

require 'test_helper'

class BulletinsHelperTest < ActionView::TestCase
  test 'hides only the complete trailing demo provenance' do
    description = "Phone in good condition\n\nДемонстрационная запись из учебного проекта. [CLASSIFIEDS_DEMO_SOURCE_ID:908005760]"

    assert_equal 'Phone in good condition', public_bulletin_description(description)
  end

  test 'leaves normal and nonmatching descriptions intact' do
    regular = "Private listing, no provenance\nOther paragraph"
    embedded = "The marker [CLASSIFIEDS_DEMO_SOURCE_ID:42] is quoted in the text."

    assert_equal regular, public_bulletin_description(regular)
    assert_equal embedded, public_bulletin_description(embedded)
  end
end
