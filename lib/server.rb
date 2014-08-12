require 'sinatra/base'
require 'sinatra/param'

class Server < Sinatra::Base
  helpers Sinatra::Param

  #
  # Expects to be posted cookbook params that are used to kick off
  # a +CookbookWorker+ which does all the real work.
  #
  post '/jobs' do
    param :cookbook_name, String, required: true
    param :cookbook_version, String, required: true
    param :cookbook_artifact_url, String, required: true

    CookbookWorker.perform_async(params)
  end
end
