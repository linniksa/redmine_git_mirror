
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

  def github
    common_webhook("x-github-event")
  end

  def gitea
    common_webhook("X-Gitea-Event")
  end

  # process github webhook request
  private def common_webhook(event_header)
    event = request.headers[event_header]
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
end
