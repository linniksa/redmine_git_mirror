
require File.expand_path('../../test_helper.rb', __FILE__)

class SettingsTest < GitMirrorUITestCase
  fixtures :users

  def test_save_setting
    settings = RedmineGitMirror::Settings

    log_user('admin', 'admin')

    assert_not settings.url_change_allowed?

    visit '/settings/plugin/redmine_git_mirror'
    within('#settings form') do
      check('Allow users to change URL')
      check('ssh://site/project.git')

      click_button('Apply', :exact => true)
    end
    assert page.has_content?('Successful update')

    assert_equal %w[http https ssh scp], settings.allowed_schemes
    assert settings.url_change_allowed?
    assert settings.prevent_multiple_clones?
    assert settings.search_clones_in_all_schemes?

    within('#settings form') do
      uncheck('Allow users to change URL')
      uncheck('Prevent adding same remote url twice')

      click_link('Uncheck all')
      check('git@site:project.git')

      click_button('Apply', :exact => true)
    end
    assert page.has_content?('Successful update')

    assert_equal %w[scp], settings.allowed_schemes
    assert_not settings.url_change_allowed?
    assert_not settings.prevent_multiple_clones?
  end
end
