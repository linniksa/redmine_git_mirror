
require 'open3'

class Repository::GitMirror < Repository::Git

  before_validation :validate_url, on: :create
  before_validation :set_defaults, on: :create
  after_validation :init_repo, on: :create
  after_commit :fetch, on: :create

  before_destroy :remove_repo

  scope :active, lambda {
    joins(:project).merge(Project.active)
  }

  private def remove_repo
    root_url = self.root_url.to_s

    return if root_url.empty?
    return if root_url == '/'
    return if root_url.to_s.length <= 15

    # check git dirs and files
    return unless Dir.exist? root_url + '/config'
    return unless Dir.exist? root_url + '/object'

    FileUtils.rm_rf root_url
  end

  private def validate_url
    return if url.to_s.empty?

    begin
      parsed_url = ::GitMirror::URL.parse(url)
    rescue Exception => msg
      errors.add :url, msg.to_s
      return
    end

    unless parsed_url.remote?
      errors.add :url, 'should be remote url'
      return
    end

    err = ::GitMirror::Git.check_remote_url(parsed_url)
    errors.add :url, err if err
  end

  private def set_defaults
    return unless self.errors.empty? && !url.to_s.empty?

    parsed_url = ::GitMirror::URL.parse(url)
    if identifier.empty?
      identifier = File.basename(parsed_url.path, ".*")
      self.identifier = identifier if /^[a-z][a-z0-9_-]*$/.match(identifier)
    end

    self.root_url = ::GitMirror::Settings.path + '/' +
      Time.now.strftime("%Y%m%d%H%M%S%L") +
      "_" +
      (parsed_url.host + parsed_url.path).gsub(/[\\\/]+/, '_').gsub(/[^A-Za-z._-]/, '')[0..64]
  end

  private def init_repo
    return unless self.errors.empty?

    err = ::GitMirror::Git.init(root_url, url)
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

    err = ::GitMirror::Git.fetch(root_url, url)
    Rails.logger.warn 'Err with fetching: ' + err if err

    remove_unreachable_commits
    fetch_changesets(true)
  end

  private def remove_unreachable_commits
    commits, e = ::GitMirror::Git.unreachable_commits(root_url)
    if e
      Rails.logger.warn 'Err when fetching unreachable commits: ' + e
      return
    end

    return if commits.empty?

    # remove commits from heads extra info
    h = extra_info["heads"]
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

    ::GitMirror::Git.prune(root_url) if commits.length >= 10
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
