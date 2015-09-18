require "net/http"
require "rubygems/package"
require "foodcritic"

class CookbookArtifact
  #
  # Accessors
  #
  attr_accessor :url, :archive, :directory, :job_id

  #
  # Initializes a +CookbookArtifact+ downloading and unarchiving the
  # artifact from the given url.
  #
  # @param [String] the url where the artifact lives
  # @param [String] the id of the job in charge of processing the artifact
  #
  def initialize(url, job_id)
    @url = url
    @job_id = job_id
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
    args = [directory, "-f #{ENV["FOODCRITIC_FAIL_TAGS"]}"]
    ENV["FOODCRITIC_TAGS"].split.each do |tag|
      args.push("-t #{tag}")
    end if ENV["FOODCRITIC_TAGS"]
    cmd = FoodCritic::CommandLine.new(args)
    result, _status = FoodCritic::Linter.run(cmd)

    return result.to_s, result.failed?
  end

  #
  # Removes the unarchived directory returns nil if the directory
  # doesn't exist.
  #
  # @return [Fixnum] the status code from the operation
  #
  def cleanup
    FileUtils.remove_dir("/tmp/cook/#{job_id}", :force => false)
  end

  private

  #
  # Downloads an artifact from a url and writes it to the filesystem.
  #
  # @return [Tempfile] the artifact
  #
  def download
    file = Tempfile.new("archive")

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
      root = File.expand_path("/tmp/cook/#{job_id}/#{tar.first.header.name.split("/")[0]}")
      tar.rewind

      tar.each do |entry|
        next unless entry.file?

        destination_file = File.expand_path("/tmp/cook/#{job_id}/#{entry.header.name}")
        destination_dir = File.dirname(destination_file)

        FileUtils.mkdir_p destination_dir unless File.directory?(destination_dir)

        file = File.open(destination_file, "w+")
        file << entry.read
        file.close
      end

      return root
    end
  end
end
