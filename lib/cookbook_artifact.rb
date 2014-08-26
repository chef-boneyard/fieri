require 'rubygems/package'
require 'foodcritic'

class CookbookArtifact
  #
  # Accessors
  #
  attr_accessor :url, :archive, :directory

  #
  # Initializes a +CookbookArtifact+ downloading and unarchiving the
  # artifact from the given url.
  #
  # @param [String] the url where the artifact lives
  #
  def initialize(url)
    @url = url
    @archive = download
    @directory = unarchive
  end

  #
  # Runs FoodCritic against an artifact.
  #
  # @return [Boolean] whether or not FoodCritic passed
  # @return [String] the would be command line out from FoodCritic
  #
  def criticize
    cmd = FoodCritic::CommandLine.new([directory, "-f #{ENV['FOODCRITIC_FAIL_TAGS']}"])
    result, _status = FoodCritic::Linter.check(cmd)

    return result.to_s, result.failed?
  end

  private

  #
  # Downloads an artifact from a url and writes it to the filesystem.
  #
  # @return [Tempfile] the artifact
  #
  def download
    file = Tempfile.new('archive')

    Net::HTTP.get_response URI.parse(url) do |response|
      response.read_body do |segment|
        file.write(segment)
      end
    end

    file.close
    file
  end

  #
  # Unarchives an artifact into the tmp directory. The unarchived artifact
  # will be deleted when the +CookbookArtifact+ is garbage collected.
  #
  # @return [String] the directory where the unarchived artifact lives.
  #
  def unarchive
    Gem::Package::TarReader.new(Zlib::GzipReader.open(archive.path)) do |tar|
      root = File.expand_path("./tmp/#{tar.first.header.name.split('/')[0]}")
      tar.rewind

      tar.each do |entry|
        next unless entry.file?

        destination_file = File.expand_path("./tmp/#{entry.header.name}")
        destination_dir = File.dirname(destination_file)

        FileUtils.mkdir_p destination_dir unless File.directory?(destination_dir)

        file = File.open(destination_file, 'w+')
        file << entry.read
        file.close
      end

      ObjectSpace.define_finalizer(self, proc { FileUtils.remove_dir(root) })

      return root
    end
  end
end
