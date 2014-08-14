require_relative './test_helper'

describe CookbookArtifact do
  let(:artifact) { CookbookArtifact.new('http://example.com/apache.tar.gz') }

  before do
    stub_request(:get, 'http://example.com/apache.tar.gz').
      to_return(
        body: File.open(File.expand_path('./tests/fixtures/apache.tar.gz')),
        status: 200
      )
  end

  describe '#initalize' do
    it 'assigns #url' do
      assert_equal 'http://example.com/apache.tar.gz', artifact.url
    end

    it 'assigns #archive' do
      assert artifact.archive.is_a?(File)
    end

    it 'assigns #directory' do
      assert_equal File.expand_path('./tmp/apache2'), artifact.directory
    end
  end

  describe '#criticize' do
    it 'it returns the feedback and status from the FoodCritic run' do
      feedback, status = artifact.criticize

      assert_match(/FC023/, feedback)
      assert_equal true, status
    end
  end
end
