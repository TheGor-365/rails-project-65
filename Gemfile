# frozen_string_literal: true

source 'https://rubygems.org'

gem 'aasm'
gem 'bootsnap', require: false
gem 'cssbundling-rails'
gem 'image_processing', '~> 1.2'
gem 'jbuilder'
gem 'jsbundling-rails'
gem 'kaminari'
gem 'omniauth-github'
gem 'omniauth-rails_csrf_protection'
gem 'puma', '>= 7.0'
gem 'pundit'
gem 'rails', '~> 7.2.2', '>= 7.2.2.2'
gem 'ransack'
gem 'rollbar'
gem 'sprockets-rails'
gem 'sqlite3', '>= 1.4'
gem 'stimulus-rails'
gem 'turbo-rails'
gem 'tzinfo-data', platforms: %i[windows jruby]

group :development, :test do
  gem 'brakeman', require: false
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'dotenv-rails'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rails-omakase', require: false
end

group :development do
  gem 'web-console'
end

group :test do
  gem 'capybara'
  gem 'faker'
  gem 'selenium-webdriver'
end

group :production do
  gem 'pg', '~> 1.5'
end
