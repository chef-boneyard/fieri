require_relative '../test_helper'

describe CookbookWorker do
  before do
    stub_request(:get, 'http://example.com/apache.tar.gz').
      to_return(
        body: File.open(File.expand_path('./tests/fixtures/apache.tar.gz')),
        status: 200
      )

    stub_request(:post, ENV['RESULTS_ENDPOINT'])
  end

  it 'sends a post request to the results endpoint' do
    CookbookWorker.new.perform(
      'cookbook_artifact_url' => 'http://example.com/apache.tar.gz',
      'cookbook_name' => 'apache2',
      'cookbook_version' => '1.2.0'
    )

    assert_requested(:post, ENV['RESULTS_ENDPOINT'], times: 1) do |req|
      req.body =~ /foodcritic_failure=true/
      req.body =~ /FC023/
    end
  end
end
