# frozen_string_literal: true

module ApplicationHelper
  LOCALE_FLAGS = {
    ru: '🇷🇺',
    en: '🇬🇧',
    hy: '🇦🇲'
  }.freeze

  LOCALE_NAMES = {
    ru: 'Русский',
    en: 'English',
    hy: 'Հայերեն'
  }.freeze

  def locale_flag(locale)
    LOCALE_FLAGS.fetch(locale.to_sym)
  end

  def locale_name(locale)
    LOCALE_NAMES.fetch(locale.to_sym)
  end

  # Preserve the current page's route and GET filters without accepting an
  # external host or carrying over an old locale query parameter.
  def locale_switch_path(locale)
    route = request.path_parameters.except('locale', :locale)
    query = request.query_parameters.except('locale', :locale)
    url_for(route.merge(query).merge(locale: locale.to_s, only_path: true))
  end
end
