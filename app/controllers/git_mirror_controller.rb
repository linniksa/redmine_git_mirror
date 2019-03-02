
class GitMirrorController < ActionController::Base

  # abstract hook for repo update via remote url
  def fetch
    found = fetch_by_urls(params[:url])
    head found ? 202 : 404
  end

  # process gitlab webhook request
  def gitlab
    event = params[:event_name]
    unless request.post? && event
      head 400
    end

    project = params[:project]
    unless %w[push repository_update].include?(event.to_s)
      head 200
      return
    end

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
