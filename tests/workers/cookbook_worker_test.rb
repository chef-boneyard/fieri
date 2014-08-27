require_relative '../test_helper'

describe CookbookWorker do
  before do
    #
    # Stubs criticize for speed!
    #
    CookbookArtifact.any_instance.stubs(:criticize).
      returns('FC023', true)

    #
    # Stubs cleanup so we can test the creation of unique
    # directories.
    #
    CookbookArtifact.any_instance.stubs(:cleanup).
      returns(0)

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

  it 'creates a unique directory for each job to work within' do
    Sidekiq::Testing.inline! do
      job_id_1 = CookbookWorker.perform_async(
        'cookbook_artifact_url' => 'http://example.com/apache.tar.gz',
        'cookbook_name' => 'apache2',
        'cookbook_version' => '1.2.0'
      )

      job_id_2 = CookbookWorker.perform_async(
        'cookbook_artifact_url' => 'http://example.com/apache.tar.gz',
        'cookbook_name' => 'apache2',
        'cookbook_version' => '1.2.0'
      )

      assert Dir.exist?("/tmp/cook/#{job_id_1}")
      assert Dir.exist?("/tmp/cook/#{job_id_2}")
    end
  end
end
