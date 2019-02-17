
require File.expand_path('../../test_helper.rb', __FILE__)

class SettingsTest < GitMirrorUITestCase
  fixtures :users, :projects, :enabled_modules

  setup do
    Setting.enabled_scm = %w(GitMirror)
    Repository.delete_all
  end

  teardown do
    Repository.delete_all
  end

  def test_enable
    log_user('admin', 'admin')

    visit '/projects/ecookbook/settings'
    click_link('Repositories')
    click_link('New repository')

    within('#repository-form') do
      fill_in('URL', :with => 'https://github.com/linniksa/redmine_git_mirror.git')

      click_button('Create', :exact => true)
    end

    click_link('Repository')

    assert page.has_content?('redmine_git_mirror')
    assert page.has_content?('README.md')
  end

  def test_ssh_error
    log_user('admin', 'admin')

    visit '/projects/ecookbook/repositories/new'

    within('#repository-form') do
      fill_in('URL', :with => 'git@github.com:linniksa/redmine_git_mirror.git')

      click_button('Create', :exact => true)
    end

    assert_match /Permission denied/, find('#errorExplanation').text.to_s.strip
  end
end
