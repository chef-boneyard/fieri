require 'sinatra/reloader'
require 'sinatra/base'
require 'sinatra/param'
require 'json'
require 'sidekiq/api'

class Server < Sinatra::Base
  helpers Sinatra::Param

  configure :development do
    register Sinatra::Reloader
  end

  REACHABLE = 'REACHABLE'
  UNKNOWN = 'UNKNOWN'
  UNREACHABLE = 'UNREACHABLE'

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

  get '/status' do
    content_type :json

    redis_health = { status: REACHABLE }
    sidekiq_health = { status: REACHABLE }

    begin
      sidekiq_health.store(:jobs, CookbookWorker.jobs.size)
    rescue Redis::TimeoutError
      sidekiq_health.store(:status, UNKNOWN)
      redis_health.store(:status, UNKNOWN)
    rescue Redis::CannotConnectError
      sidekiq_health.store(:status, UNREACHABLE)
      redis_health.store(:status, UNREACHABLE)
    rescue NoMethodError
      sidekiq_health.store(:jobs, 0)
    end

    if redis_health.fetch(:status) == 'REACHABLE' &&
         sidekiq_health.fetch(:status) == 'REACHABLE'
      status = 'ok'
    else
      status = 'not ok'
    end

    {
      'status' => status,
      'sidekiq' => {
        'status' => sidekiq_health.fetch(:status),
        'jobs' => sidekiq_health.fetch(:jobs)
      },
      'redis' => {
        'status' => redis_health.fetch(:status)
      }
    }.to_json
  end
end
