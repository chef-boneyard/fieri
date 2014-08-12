ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/pride'
require 'rack/test'

require_relative '../endpoint'

module MiniTest
  class Spec
    include Rack::Test::Methods

    def app
      Sinatra::Application
    end
  end
end
