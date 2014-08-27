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

  #
  # Returns the status of the app, Redis and Sidekiq. Also returns the number of
  # jobs in the +CookbookWorker+ queue.
  #
  get '/status' do
    content_type :json

    redis_health = { status: REACHABLE }
    sidekiq_health = { status: REACHABLE }

    begin
      Sidekiq::Queue.new.tap do |queue|
        sidekiq_health.store(:latency, queue.latency)
        sidekiq_health.store(:queued_jobs, queue.size)
      end

      sidekiq_health.store(:active_workers, Sidekiq::Workers.new.size)
      sidekiq_health.store(:dead_jobs, Sidekiq::DeadSet.new.size)
      sidekiq_health.store(:retryable_jobs, Sidekiq::RetrySet.new.size)

      Sidekiq::Stats.new.tap do |stats|
        sidekiq_health.store(:total_processed, stats.processed)
        sidekiq_health.store(:total_failed, stats.failed)
      end

      redis_info = Sidekiq.redis { |client| client.info }

      %w(uptime_in_seconds connected_clients used_memory used_memory_peak).each do |key|
        redis_health.store(key, redis_info.fetch(key, -1).to_i)
      end
    rescue Redis::TimeoutError
      sidekiq_health.store(:status, UNKNOWN)
      redis_health.store(:status, UNKNOWN)
    rescue Redis::CannotConnectError
      sidekiq_health.store(:status, UNREACHABLE)
      redis_health.store(:status, UNREACHABLE)
    end

    if redis_health.fetch(:status) == 'REACHABLE' &&
         sidekiq_health.fetch(:status) == 'REACHABLE'
      status = 'ok'
    else
      status = 'not ok'
    end

    {
      'status' => status,
      'sidekiq' => sidekiq_health,
      'redis' => redis_health
    }.to_json
  end
end
