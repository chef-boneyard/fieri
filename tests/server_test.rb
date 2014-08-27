require_relative './test_helper'

describe '/jobs' do
  describe 'when a valid job is posted' do
    it 'should return a 200' do
      post '/jobs', valid_params
      assert_equal 200, last_response.status
    end

    it 'should queue a cookbook worker' do
      post '/jobs', valid_params
      assert_equal 1, CookbookWorker.jobs.size
    end
  end

  describe 'when an invalid job is posted' do
    it 'should return a 400' do
      post '/jobs', cookbook_name: 'redis'
      assert_equal 400, last_response.status
    end
  end
end

describe '/status' do
  it 'should return a 200' do
    get '/status'

    assert_equal 200, last_response.status
  end

  it 'should return the status' do
    Sidekiq::Testing.disable! do
      post '/jobs', valid_params
      get '/status'

      assert_match(/ok/, last_response.body)
      assert_match(/\"queued_jobs\":1/, last_response.body)
    end
  end
end

def valid_params
  {
    cookbook_name: 'redis',
    cookbook_version: '1.2.0',
    cookbook_artifact_url: 'http://example.com/apache.tar.gz'
  }
end
