source 'https://rubygems.org'

gem 'sinatra'
gem 'sinatra-param'
gem 'sinatra-contrib'
gem 'sidekiq'
gem 'rake'
gem 'foodcritic'
gem 'dotenv'
gem 'unicorn'

gem 'sentry-raven', '~> 0.8.0', require: false

group :test do
  gem 'webmock'
  gem 'rack-test'
  gem 'minitest'
  gem 'minitest-focus'
  gem 'mocha'
end

group :development, :test do
  gem 'rubocop'
  gem 'byebug'
end

group :doc do
  gem 'yard', require: false
end
