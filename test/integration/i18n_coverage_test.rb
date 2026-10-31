# frozen_string_literal: true

require 'test_helper'
require 'yaml'
require 'set'

# Global guardrail for three-language UI coverage. This intentionally checks
# application dictionaries, not Rails/Ruby/third-party framework fallbacks.
class I18nCoverageTest < ActiveSupport::TestCase
  LANGUAGES = %w[ru en hy].freeze
  SCANNED_SOURCES = %w[
    app/views/**/*.erb
    app/javascript/controllers/**/*.js
    app/controllers/web/**/*.rb
    app/controllers/concerns/**/*.rb
    app/models/*.rb
    app/helpers/*.rb
  ].freeze

  test 'every YAML document has exactly one root locale and no duplicate mapping keys' do
    locale_files.each do |path|
      document = Psych.parse_file(path)
      assert document, "Could not parse #{path}"
      assert_no_duplicate_keys(document.root, path)
      content = Psych.safe_load_file(path, aliases: true)
      assert content.is_a?(Hash), "Invalid YAML structure in #{path}"
      assert_equal 1, content.size, "Expected one locale in #{path}"
      assert LANGUAGES.include?(content.keys.first), "Unexpected locale in #{path}"
    end
  end

  test 'application locale dictionaries have matching keys and interpolation arguments' do
    data = locale_content
    reference = data.fetch('ru')

    LANGUAGES.each do |locale|
      keys = data.fetch(locale).keys
      assert_equal reference.keys.sort, keys.sort, "Key mismatch in #{locale}"

      reference.each do |key, value|
        translated = data.fetch(locale).fetch(key)
        assert translated.is_a?(String), "#{locale}.#{key} must be a string"
        assert translated.present?, "#{locale}.#{key} must not be empty"
        assert_equal interpolation_variables(value), interpolation_variables(translated),
                     "Interpolation mismatch in #{locale}.#{key}"
      end
    end
  end

  test 'English and Armenian UI dictionaries do not contain untranslated Cyrillic copy' do
    locale_content.each do |locale, entries|
      next if locale == 'ru'

      entries.each do |key, value|
        assert_no_match(/[А-Яа-яЁё]/, value, "Untranslated Russian text in #{locale}.#{key}")
      end
    end
  end

  test 'all literal translation keys referenced by app code exist in three languages' do
    paths = source_paths
    missing = []
    paths.each do |path|
      File.read(path).scan(/(?<![\w])(?:I18n\.)?t\(\s*['"]([a-z][\w.]+)['"]/) do |match|
        key = match.first
        LANGUAGES.each do |locale|
          missing << "#{relative_path(path)}: #{locale}.#{key}" unless I18n.exists?(key, locale)
        end
      end
    end

    assert_empty missing, "Missing static i18n keys:\n#{missing.join("\n")}"
  end

  test 'ERB, Stimulus, controllers and models contain no hardcoded Russian UI copy' do
    # Names for the fixed Russian seed categories and the intentional demo
    # source marker are domain data, not translated UI labels.
    exceptions = {
      'app/helpers/application_helper.rb' => [ /ru: 'Русский'/ ],
      'app/helpers/bulletins_helper.rb' => [
        /^\s*'Одежда' => /, /^\s*'Услуги' => /, /^\s*'Электроника' => /,
        /Демонстрационная запись из учебного проекта/
      ]
    }

    remaining = source_paths.flat_map do |path|
      relative = relative_path(path)
      File.foreach(path).with_index(1).filter_map do |line, line_number|
        next unless line.match?(/[А-Яа-яЁё]/)
        next if exceptions.fetch(relative, []).any? { |pattern| line.match?(pattern) }

        "#{relative}:#{line_number}: #{line.strip}"
      end
    end

    assert_empty remaining, "Hardcoded Russian text remains:\n#{remaining.join("\n")}"
  end

  private

  def locale_files
    @locale_files ||= (
      Dir[Rails.root.join('config/locales/*.yml').to_s] +
      Dir[Rails.root.join('config/locales/**/*.yml').to_s]
    ).uniq.sort
  end

  def source_paths
    @source_paths ||= SCANNED_SOURCES.flat_map do |pattern|
      Dir[Rails.root.join(pattern).to_s]
    end.uniq.sort
  end

  def relative_path(path)
    Pathname(path).relative_path_from(Rails.root).to_s
  end

  def locale_content
    @locale_content ||= begin
      values = LANGUAGES.index_with { {} }
      locale_files.each do |path|
        Psych.safe_load_file(path, aliases: true).each do |locale, root|
          flatten(root).each do |key, value|
            existing = values.fetch(locale)[key]
            assert_equal existing, value, "Conflicting locale key #{locale}.#{key} in #{path}" if existing
            values.fetch(locale)[key] = value
          end
        end
      end
      values
    end
  end

  def flatten(tree, prefix = nil)
    tree.each_with_object({}) do |(key, value), result|
      name = [ prefix, key ].compact.join('.')
      if value.is_a?(Hash)
        result.merge!(flatten(value, name))
      else
        result[name] = value
      end
    end
  end

  def interpolation_variables(text)
    text.to_s.scan(/%\{([a-z_]\w*)\}/).flatten.sort
  end

  def assert_no_duplicate_keys(node, file)
    case node
    when Psych::Nodes::Mapping
      children = node.children.each_slice(2).to_a
      keys = children.map { |key, _value| key.value }
      assert_equal keys.uniq, keys, "Duplicate YAML key in #{file} at line #{node.start_line + 1}"
      children.each { |_key, value| assert_no_duplicate_keys(value, file) }
    when Psych::Nodes::Sequence
      node.children.each { |child| assert_no_duplicate_keys(child, file) }
    end
  end
end
