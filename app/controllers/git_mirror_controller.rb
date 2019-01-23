
class GitMirrorController < ActionController::Base

  # abstract hook for repo update via remote url
  def fetch
    return unless check_enabled(params[:key])

    found = fetch_by_urls(params[:url])
    head found ? 200 : 404
  end

  # process gitlab webhook request
  def gitlab
    return unless check_enabled(request.headers["x-gitlab-token"])

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

    ssh_url = project[:git_ssh_url]
    http_url = project[:git_http_url]

    unless ssh_url && http_url
      head 422
      return
    end

    found = fetch_by_urls([ssh_url, http_url])
    head found ? 202 : 404
  end

  private def fetch_by_urls(urls)
    found = false
    Repository::GitMirror.joins(:project).merge(Project.active).where(url: urls).find_each do |repository|
      return unless repository.project.active?
      found = true unless found

      repository.fetch()
    end

    found
  end

  private def check_enabled(token)
    return true if Setting.sys_api_enabled? && token.to_s == Setting.sys_api_key

    render :plain => 'Access denied. Repository management WS is disabled or key is invalid.', :status => 403
    false
  end
end
