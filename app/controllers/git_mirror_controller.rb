
class GitMirrorController < ActionController::Base

  # abstract hook for repo update via remote url
  def fetch
    url = params[:url]
    begin
      RedmineGitMirror::URL.parse(url)
    rescue
      head 400
      return
    end
    found = fetch_by_urls([url])

    head found ? 202 : 404
  end

  # process gitlab webhook request
  def gitlab
    unless RedmineGitMirror::Settings.gitlab_hook_enabled?
      head 404
      return
    end

    unless verify_gitlab_signature
      head 401
      return
    end

    event = params[:event_name]
    unless request.post? && event
      head 400
      return
    end

    unless %w[push repository_update].include?(event.to_s)
      head 200
      return
    end

    project = params[:project]
    unless project
      head 422
      return
    end

    urls = []

    [:git_ssh_url, :git_http_url].each do |p|
      url = project[p].to_s

      urls.push(url) if url.length > 0
    end

    if urls.length <= 0
      head 422
      return
    end

    found = fetch_by_urls(urls)
    head found ? 202 : 404
  end

  # process github webhook request
  def github
    unless RedmineGitMirror::Settings.github_hook_enabled?
      head 404
      return
    end

    unless verify_github_signature
      head 401
      return
    end

    event = request.headers["x-github-event"]
    unless request.post? && event
      head 400
      return
    end

    unless %w[push].include?(event.to_s)
      head 200
      return
    end

    payload = params[:payload]

    if payload && request.content_type != 'application/json'
      payload = JSON.parse(payload, :symbolize_names => true)
    else
      payload = params
    end

    unless payload
      head 422
      return
    end

    repository = payload[:repository]
    unless repository
      head 422
      return
    end

    urls = []

    [:ssh_url, :clone_url, :git_url].each do |p|
      url = repository[p].to_s

      urls.push(url) if url.length > 0
    end

    if urls.length <= 0
      head 422
      return
    end

    found = fetch_by_urls(urls)
    head found ? 202 : 404
  end

  private def fetch_by_urls(urls)
    urls_to_search = []

    urls.each do |url|
      begin
        urls_to_search.concat RedmineGitMirror::URL.parse(url).vary
      rescue Exception => _
        urls_to_search.push(url)
      end
    end

    found = false
    Repository::GitMirror.active.where(url: urls_to_search).find_each do |repository|
      found = true unless found
      repository.fetch()
    end

    found
  end

  private def verify_gitlab_signature
    expectedToken = RedmineGitMirror::Settings.gitlab_token
    return true unless expectedToken.present?

    token = request.headers["X-Gitlab-Token"]
    return expectedToken == token
  end

  private def verify_github_signature
    secretKey = RedmineGitMirror::Settings.github_secret_key
    return true unless secretKey.present?

    signature = request.headers["X-Hub-Signature-256"]
    return false unless signature.present?

    digest = OpenSSL::Digest.new("sha256")
    expected_signature = "sha256=" + OpenSSL::HMAC.hexdigest(digest, secretKey, request.body.read)
    return Rack::Utils.secure_compare(expected_signature, signature)
  end
end
