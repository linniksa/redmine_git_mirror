
class Repository::GitMirror < Repository::Git

  before_validation :validate_and_normalize_url, on: [:create, :update]
  before_validation :set_defaults, on: :create
  after_validation :init_repo, on: :create
  after_validation :validate_branches, on: [:create, :update]
  after_commit :fetch, on: [:create, :update]

  after_validation :update_remote_url, on: :update

  before_destroy :remove_repo

  scope :active, lambda {
    joins(:project).merge(Project.active)
  }

  safe_attributes 'url', :if => lambda { |repository, user|
    repository.new_record? || RedmineGitMirror::Settings.url_change_allowed?
  }

  safe_attributes 'extra_info', :if => lambda {|repository, user|
    repository.new_record? || RedmineGitMirror::Settings.branches_to_fetch_change_allowed?
  }

  safe_attributes 'branches_to_fetch', :if => lambda { |repository, user|
    repository.new_record? || RedmineGitMirror::Settings.branches_to_fetch_change_allowed?
  }

  def branches_to_fetch
    return "*" unless extra_info && extra_info["branches_to_fetch"]
    extra_info["branches_to_fetch"]
  end

  def refspecs
    branches_to_fetch.split(/,/).collect { |m|m.strip }.map { |branch| "+refs/heads/%s:refs/heads/%s" % [branch, branch] }
  end

  private def update_remote_url
    return unless self.errors.empty?
    return unless self.url_changed?

    r, err = RedmineGitMirror::Git.get_remote_url(root_url)
    if err
      errors.add :url, err
      return
    end

    return if r == url

    err = RedmineGitMirror::Git.set_remote_url(root_url, url)
    errors.add :url, err if err
  end

  private def remove_repo
    root_url = self.root_url.to_s

    return if root_url.empty?
    return if root_url == '/'
    return if root_url.to_s.length <= 15

    # check git dirs and files
    return unless File.exist? root_url + '/config'
    return unless Dir.exist? root_url + '/objects'

    FileUtils.rm_rf root_url
  end

  private def validate_and_normalize_url
    return unless self.new_record? || self.url_changed?

    url = self.url.to_s.strip

    return if url.to_s.empty?

    begin
      parsed_url = RedmineGitMirror::URL.parse(url)
    rescue Exception => msg
      errors.add :url, msg.to_s
      return
    end

    unless parsed_url.remote?
      errors.add :url, 'should be remote url'
      return
    end

    unless parsed_url.scheme?(*RedmineGitMirror::Settings.allowed_schemes)
      s = RedmineGitMirror::Settings.allowed_schemes
      err = s.empty?? 'no allowed schemes' : "scheme not allowed, only #{s.join', '} is allowed"
      errors.add :url, err
      return
    end

    if parsed_url.has_credential?
      errors.add :url, 'cannot use credentials'
      return
    end

    self.url = parsed_url.normalize

    err = RedmineGitMirror::Git.check_remote_url(self.url)
    if err
      errors.add :url, err
      return
    end

    if RedmineGitMirror::Settings.prevent_multiple_clones?
      urls = RedmineGitMirror::URL.parse(url).vary(
        :all => RedmineGitMirror::Settings.search_clones_in_all_schemes?
      )

      if Repository::GitMirror.where(url: urls).where.not(id: self.id).exists?
        errors.add :url, 'is already mirrored in redmine'
        return
      end
    end
  end

  private def validate_branches
    err = RedmineGitMirror::Git.fetch(root_url, url, refspecs, dry_run=true)
    if err
      errors.add :branches_to_fetch, err
      return
    end
  end

  private def set_defaults
    return unless self.errors.empty? && !url.to_s.empty?

    parsed_url = RedmineGitMirror::URL.parse(url)
    if identifier.empty?
      identifier = File.basename(parsed_url.path, ".*")
      self.identifier = identifier if /^[a-z][a-z0-9_-]*$/.match(identifier)
    end

    self.root_url = RedmineGitMirror::Settings.path + '/' +
      Time.now.strftime("%Y%m%d%H%M%S%L") +
      "_" +
      (parsed_url.host + parsed_url.path.gsub(/\.git$/, '')).gsub(/[\\\/]+/, '_').gsub(/[^A-Za-z._-]/, '')[0..64]
  end

  private def init_repo
    return unless self.errors.empty?

    err = RedmineGitMirror::Git.init(root_url, url, refspecs)
    errors.add :url, err if err
  end

  def fetch_changesets(fetch = false)
    return unless fetch
    super()
  end

  def fetch
    return if @fetched
    @fetched = true

    puts "Fetching repo #{url} to #{root_url}"

    err = RedmineGitMirror::Git.fetch(root_url, url, refspecs)
    Rails.logger.warn 'Err with fetching: ' + err if err

    if RedmineGitMirror::Settings.remove_unreachable_on_fetch?
      remove_unreachable_commits
    end
    fetch_changesets(true)
  end

  def remove_unreachable_commits
    commits, e = RedmineGitMirror::Git.unreachable_commits(root_url)
    if e
      Rails.logger.warn 'Err when fetching unreachable commits: ' + e
      return
    end

    return if commits.empty?

    # remove commits from heads extra info
    h = extra_info ? extra_info["heads"] : nil
    if h
      h1 = h.dup
      commits.each { |c| h1.delete(c) }

      if h1.length != h.length
        n = {}
        n["heads"] = h1

        merge_extra_info(n)
        save
      end
    end

    Changeset.where(repository: self, revision: commits).destroy_all

    RedmineGitMirror::Git.prune(root_url) if commits.length >= 10
  end

  class << self
    def scm_name
      'Git Mirror'
    end

    def human_attribute_name(attribute_key_name, *args)
      attr_name = attribute_key_name.to_s

      Repository.human_attribute_name(attr_name, *args)
    end

    # Fetches new changes for all git mirror repositories in active projects
    # Can be called periodically by an external script
    # eg. bin/rails runner "Repository::GitMirror.fetch"
    def fetch
      Repository::GitMirror.active.find_each(&:fetch)
    end
  end

end
