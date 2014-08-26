ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/focus'
require 'mocha/mini_test'
require 'rack/test'
require 'sidekiq/testing'
require 'webmock/minitest'
require 'byebug'

require_relative '../lib/app'

#
# In most cases, tests which queue jobs should
# only care that the job was queued, and not care about the result.
#
Sidekiq::Testing.fake!

module MiniTest
  class Spec
    include Rack::Test::Methods

    before do
      Sidekiq::Worker.clear_all
    end

    def app
      Server
    end
  end
end
