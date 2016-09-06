module Pronto
  class BitbucketServer
    def initialize(repo)
      @repo = repo
      @config = Config.new
      @comment_cache = {}
      @pull_id_cache = {}
    end

    def pull_comments(sha)
      @comment_cache["#{pull_id}/#{sha}"] ||= begin
        client.pull_comments(slug, pull_id).map do |comment|
          Comment.new(sha, comment.text, comment["anchor"]["path"], comment["anchor"]["line"])
        end
      end
    end

    def create_pull_comment(comment)
      @config.logger.log("Creating pull request comment on #{pull_id}")
      client.create_pull_comment(slug, pull_id, comment.body,
                                 comment.path, comment.position)
    end

    private

    def slug
      return @config.bitbucket_server_slug if @config.bitbucket_server_slug
      abort "Please set slug parameter"
    end

    def client
      @client ||= BitbucketServerClient.new(@config.bitbucket_server_username,
                                            @config.bitbucket_server_password,
                                            @config.bitbucket_server_api_endpoint)
    end

    def pull_id
      pull ? pull.id.to_i : env_pull_id.to_i
    end

    def env_pull_id
      ENV['PULL_REQUEST_ID']
    end

    def pull
      @pull ||= if env_pull_id
                  pull_requests.find { |pr| pr.id.to_i == env_pull_id.to_i }
                elsif @repo.branch
                  pull_requests.find { |pr| pr["fromRef"]["displayId"] == @repo.branch }
                end
    end

    def pull_requests
      @pull_requests ||= client.pull_requests(slug)
    end
  end
end
