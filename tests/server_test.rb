require_relative './test_helper'

describe '/jobs' do
  let(:valid_params) do
    {
      cookbook_name: 'redis',
      cookbook_version: '1.2.0',
      cookbook_artifact_url: 'https://example.com/api/v1/cookbooks/redis/versions/1.2.0/download'
    }
  end

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
    post(
      '/jobs',
      cookbook_name: 'redis',
      cookbook_version: '1.2.0',
      cookbook_artifact_url: 'https://example.com/api/v1/cookbooks/redis/versions/1.2.0/download'
    )

    get '/status'

    expected_response = {
      'status' => 'ok',
      'sidekiq' => {
        'status' => 'REACHABLE',
        'jobs' => 1
      },
      'redis' => {
        'status' => 'REACHABLE'
      }
    }

    assert_equal expected_response.to_json, last_response.body
  end
end
