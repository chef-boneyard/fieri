require 'restclient'
require 'sidekiq'

class CookbookWorker
  include Sidekiq::Worker

  def perform(params)
    cookbook = CookbookArtifact.new(params['cookbook_artifact_url'])
    feedback, status = cookbook.criticize

    RestClient.post(
      ENV['RESULTS_ENDPOINT'],
      fieri_key: ENV['AUTH_TOKEN'],
      cookbook_name: params['cookbook_name'],
      cookbook_version: params['cookbook_version'],
      foodcritic_feedback: feedback,
      foodcritic_failure: status
    )
  end
end
