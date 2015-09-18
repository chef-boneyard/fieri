ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "minitest/pride"
require "minitest/focus"
require "mocha/mini_test"
require "rack/test"
require "sidekiq/testing"
require "webmock/minitest"
require "byebug"

require_relative "../lib/app"

module MiniTest
  class Spec
    include Rack::Test::Methods

    before do
      Sidekiq::Worker.clear_all
      Sidekiq::Queue.new.clear
    end

    def app
      Server
    end
  end
end
