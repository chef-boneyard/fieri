require 'dotenv'

Dotenv.load

require_relative 'server'
require_relative 'cookbook_artifact'
require_relative 'workers/cookbook_worker'
