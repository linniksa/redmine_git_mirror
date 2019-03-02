require File.expand_path('../../test_helper', __FILE__)

class HooksTest < Redmine::IntegrationTest
  fixtures :users, :projects, :enabled_modules

  setup do
    Setting.enabled_scm = %w(GitMirror)
    Setting.sys_api_enabled = '1'
    Setting.sys_api_key = 'secret'

    Repository.delete_all

    r = Repository::GitMirror.new
    r.url = 'https://github.com/linniksa/redmine_git_mirror.git'
    r.project = Project.find(1)
    r.save!
  end

  teardown do
    Repository.delete_all
  end

  test 'gitlab hook' do
    post '/sys/git_mirror/gitlab',
         :params => {
           'event_name' => 'repository_update',
           'project' => {
             'git_http_url' => 'https://github.com/linniksa/redmine_git_mirror.git',
           }
         }.to_json,
         :headers => {
           "CONTENT_TYPE" => 'application/json',
           'X-GITLAB-TOKEN' => 'secret',
         }

    assert_response 202
  end

  test 'gitlab hook with .git' do
    post '/sys/git_mirror/gitlab',
         :params => {
           'event_name' => 'repository_update',
           'project' => {
             'git_http_url' => 'https://github.com/linniksa/redmine_git_mirror',
           }
         }.to_json,
         :headers => {
           "CONTENT_TYPE" => 'application/json',
           'X-GITLAB-TOKEN' => 'secret',
         }

    assert_response 202
  end

  test 'gitlab hook unknown url' do
    post '/sys/git_mirror/gitlab',
         :params => {
           'event_name' => 'repository_update',
           'project' => {
             'git_http_url' => 'http://example.com/some.git',
           }
         }.to_json,
         :headers => {
           "CONTENT_TYPE" => 'application/json',
           'X-GITLAB-TOKEN' => 'secret',
         }

    assert_response 404
  end

end
