require 'dotenv'

Dotenv.load

if ENV['SENTRY_URL']
  require 'raven'
  require 'raven/sidekiq'

  Raven.configure do |config|
    config.dsn = ENV['SENTRY_URL']
  end
end

require_relative 'server'
require_relative 'cookbook_artifact'
require_relative 'workers/cookbook_worker'
