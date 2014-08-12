require_relative './test_helper'

describe '/jobs' do
  it 'should return a 200 when a valid job is posted' do
    post '/jobs'
    assert last_response.ok?
  end
end
