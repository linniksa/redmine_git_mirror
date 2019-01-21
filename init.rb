require 'redmine'
require 'git_mirror/repositories_helper_patch'

Redmine::Scm::Base.add 'GitMirror'

Redmine::Plugin.register :redmine_git_mirror do
  name 'Git Mirror'
  author 'Sergey Linnik'
  description 'Add ability to create readonly mirror of remote git repository'
  version '0.5.0'
  url 'https://github.com/linniksa/redmine_git_mirror'
  author_url 'https://github.com/linniksa'

  requires_redmine :version_or_higher => '3.3.0'
end
