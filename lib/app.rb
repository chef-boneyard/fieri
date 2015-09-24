require "dotenv"
require "sidekiq"

Dotenv.load(
 File.expand_path("../../.env.#{ENV['RACK_ENV']}", __FILE__),
 File.expand_path('../../.env',  __FILE__)
)

if ENV["SENTRY_URL"]
  require "raven"
  require "raven/sidekiq"

  Raven.configure do |config|
    config.dsn = ENV["SENTRY_URL"]
  end
end

require_relative "server"
require_relative "cookbook_artifact"
require_relative "workers/cookbook_worker"
