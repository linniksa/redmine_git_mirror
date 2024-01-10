require 'redmine'
require_dependency File.dirname(__FILE__) + '/lib/redmine_git_mirror/hooks'
require_dependency File.dirname(__FILE__) + '/lib/redmine_git_mirror/git'
require_dependency File.dirname(__FILE__) + '/lib/redmine_git_mirror/ssh'
require_dependency File.dirname(__FILE__) + '/lib/redmine_git_mirror/url'
require_dependency File.dirname(__FILE__) + '/lib/redmine_git_mirror/settings'

Redmine::Scm::Base.add 'GitMirror'

Redmine::Plugin.register :redmine_git_mirror do
  name 'Git Mirror'
  author 'Sergey Linnik'
  description 'Add ability to create readonly mirror of remote git repository'
  version '0.8.0'
  url 'https://github.com/linniksa/redmine_git_mirror'
  author_url 'https://github.com/linniksa'

  requires_redmine :version_or_higher => '3.3.0'

  settings :default => RedmineGitMirror::Settings::DEFAULT, :partial => 'git_mirror/settings'

end

redmine_git_mirror_patches = proc do
  require 'repositories_helper'
  require File.dirname(__FILE__) + '/lib/redmine_git_mirror/patches/repositories_helper_patch'

  def include(klass, patch)
    klass.send(:include, patch) unless klass.included_modules.include?(patch)
  end

  include(RepositoriesHelper, RedmineGitMirror::Patches::RepositoriesHelperPatch)
end

# Patches to the Redmine core.
require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

# ActiveSupport::Reloader.to_prepare isn't used by Zeitwerk, hence include directly
if Rails::VERSION::MAJOR >= 5
  require 'repositories_helper'

  def include(klass, patch)
    klass.send(:include, patch) unless klass.included_modules.include?(patch)
  end

  include(RepositoriesHelper, RedmineGitMirror::Patches::RepositoriesHelperPatch)
elsif Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare &redmine_git_mirror_patches
else
  Dispatcher.to_prepare &redmine_git_mirror_patches
end
