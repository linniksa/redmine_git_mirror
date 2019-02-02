
require 'minitest/autorun'

require File.expand_path(File.dirname(__FILE__) + '/../../lib/git_mirror/url')

#@see https://git-scm.com/docs/git-clone#_git_urls_a_id_urls_a

class TestUrl < Minitest::Test
  def test_normalize
    url = GitMirror::URL.parse('http://test.ru//123.git')
    assert_equal 'http://test.ru/123.git', url.normalize
  end

  def test_use_ssh
    assert GitMirror::URL.parse('ssh://git@host.xz/path/to/repo.git/').uses_ssh?
    assert GitMirror::URL.parse('git@github.com:user/repo.git').uses_ssh?
  end

  cases = {
    :remote_ssh => ['ssh://git@host.xz/path/to/repo.git/', {
      :schema => 'ssh',
      :user => 'git',
      :host => 'host.xz',
      :path => '/path/to/repo.git/'
    }],

    :remote_git => ['git://host.xz/path/to/repo.git/', {
      :schema => 'git',
      :host => 'host.xz',
      :port => 9418,
      :path => '/path/to/repo.git/'
    }],

    :remote_http => ['http://git:pwd@host.xz/path/to/repo.git/', {
      :schema => 'http',
      :user => 'git',
      :password => 'pwd',
      :host => 'host.xz',
      :port => 80,
      :path => '/path/to/repo.git/'
    }],

    :remote_scp_like => ['git@github.com:user/repo.git', {
      :user => 'git',
      :host => 'github.com',
      :path => '/user/repo.git'
    }],

    :local_unix => ['/home/user/projects/test', {
      :path => '/home/user/projects/test',
    }],

    :local_file_schema => ['file:///sys/projects/my.git', {
      :schema => 'file',
      :path => '/sys/projects/my.git',
    }],

    :local_windows => ['C:\\project\\my', {
      :path => 'C:\\project\\my',
    }],
  }

  cases.each do |key, value|
    url_to_parse, expected = value
    define_method :"test_#{key}" do
      url = GitMirror::URL.parse(url_to_parse)

      if key.to_s.start_with? ('remote')
        assert_remote url
      else
        assert_local url
      end

      assert_equal expected, url.to_h
      assert_equal url_to_parse, url.to_s
    end
  end




###############################################################################
  def assert_local (url)
    assert_instance_of GitMirror::URL, url

    assert url.local?, 'local? should return true'
    assert !url.remote?, 'remote? should return false'
  end

  def assert_remote (url)
    assert_instance_of GitMirror::URL, url

    assert url.remote?, 'remote? should return true'
    assert !url.local?, 'local? should return false'
  end
end
