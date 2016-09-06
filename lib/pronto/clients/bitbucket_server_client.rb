class BitbucketServerClient
  include HTTParty

  def initialize(username, password, base_uri)
    credentials = { username: username, password: password }
    @headers = { basic_auth: credentials, headers: { "Content-type": "application/json" } }
    @base_uri = base_uri.sub(%r{/$}, "")
  end

  def commit_comments(slug, sha)
    project, repo = slug.split("/")
    response = self.class.get("#{@base_uri}/rest/api/1.0/projects/#{project}/repos/#{repo}/commits/#{sha}/comments", @headers)
    openstruct(response.parsed_response['values'])
  end

  def create_commit_comment(slug, sha, body, path, position)
    project, repo = slug.split("/")
    options = {
      body: {
        "text": body,
        "anhor": {
          "line": position,
          "lineType": "CONTEXT",
          "fileType": "FROM",
          "path": path,
          "srcPath": path,
        }
      }.to_json
    }
    options.merge!(@headers)
    self.class.post("#{@base_uri}/rest/api/1.0/projects/#{project}/repos/#{repo}/commits/#{sha}/comments", options)
  end

  def pull_comments(slug, pr_id)
    project, repo = slug.split("/")
    url = "#{@base_uri}/rest/api/1.0/projects/#{project}/repos/#{repo}/pull-requests/#{pr_id}/changes?withComments=true"
    response = self.class.get(url, @headers)
    changes = openstruct(response.parsed_response['values'])
    comments = []
    changes.select { |change| change.dig("properties", "activeComments").to_i > 0  }.each do |change|
      path = change["path"]["toString"]
      url = "#{@base_uri}/rest/api/1.0/projects/#{project}/repos/#{repo}/pull-requests/#{pr_id}/comments?path=#{path}"
      response = self.class.get(url, @headers)
      openstruct(response.parsed_response['values']).each do |comment|
        comment[:path] = path
        comments << comment
      end
    end
    comments
  end

  def pull_requests(slug)
    project, repo = slug.split("/")
    url = "#{@base_uri}/rest/api/1.0/projects/#{project}/repos/#{repo}/pull-requests?state=OPEN"
    response = self.class.get(url, @headers)
    openstruct(response.parsed_response['values'])
  end

  def create_pull_comment(slug, pull_id, body, path, position)
    project, repo = slug.split("/")
    options = {
      body: {
        "text": body,
        "anchor": {
          "line": position,
          "lineType": "ADDED",
          "fileType": "TO",
          "path": path
        }
      }.to_json
    }
    options.merge!(@headers)
    self.class.post("#{@base_uri}/rest/api/1.0/projects/#{project}/repos/#{repo}/pull-requests/#{pull_id}/comments", options)
  end

  def openstruct(response)
    response.map { |r| OpenStruct.new(r) }
  end
end
