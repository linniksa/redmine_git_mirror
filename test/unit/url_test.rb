
require 'minitest/autorun'

require File.expand_path(File.dirname(__FILE__) + '/../../lib/redmine_git_mirror/url')

#@see https://git-scm.com/docs/git-clone#_git_urls_a_id_urls_a

class TestUrl < Minitest::Test
  def test_normalize
    url = RedmineGitMirror::URL.parse('http://test.ru//123.git')
    assert_equal 'http://test.ru/123.git', url.normalize
  end

  cases = {
    :ssh => ['ssh://git@host.xz/path/to/repo.git/', [:ssh], {
      :scheme => 'ssh',
      :user => 'git',
      :host => 'host.xz',
      :path => '/path/to/repo.git/'
    }],

    :ssh_pwd => ['ssh://git:password@host.xz/path/to/repo.git/', [:ssh, :credentials], {
      :scheme => 'ssh',
      :user => 'git',
      :password => 'password',
      :host => 'host.xz',
      :path => '/path/to/repo.git/'
    }],

    :scp_like => ['git@github.com:user/repo.git', [:ssh], {
      :user => 'git',
      :host => 'github.com',
      :path => '/user/repo.git'
    }],

    :git => ['git://host.xz/path/to/repo.git/', [], {
      :scheme => 'git',
      :host => 'host.xz',
      :port => 9418,
      :path => '/path/to/repo.git/'
    }],

    :http_with_credentials => ['http://git:pwd@host.xz/path/to/repo.git/', [:credentials], {
      :scheme => 'http',
      :user => 'git',
      :password => 'pwd',
      :host => 'host.xz',
      :port => 80,
      :path => '/path/to/repo.git/'
    }],

    :http_with_user => ['http://git@host.xz/path/to/repo.git/', [:credentials], {
      :scheme => 'http',
      :user => 'git',
      :host => 'host.xz',
      :port => 80,
      :path => '/path/to/repo.git/'
    }],

    :https => ['https://gitlab.site/path/to/project.git', [], {
      :scheme => 'https',
      :host => 'gitlab.site',
      :port => 443,
      :path => '/path/to/project.git'
    }],

    :https_with_port => ['https://gitlab.site:9443/path/to/project.git', [], {
      :scheme => 'https',
      :host => 'gitlab.site',
      :port => 9443,
      :path => '/path/to/project.git'
    }],

    :unix => ['/home/user/projects/test', [:local], {
      :path => '/home/user/projects/test',
    }],

    :file_scheme => ['file:///sys/projects/my.git', [:local], {
      :scheme => 'file',
      :path => '/sys/projects/my.git',
    }],

    :windows => ['C:\\project\\my', [:local], {
      :path => 'C:\\project\\my',
    }],
  }

  cases.each do |key, value|
    url_to_parse, tags, expected = value

    define_method :"test_#{key}" do
      url = RedmineGitMirror::URL.parse(url_to_parse)
      assert_instance_of RedmineGitMirror::URL, url

      assert_equal expected, url.to_h
      assert_equal url_to_parse, url.to_s

      if tags.include? :local
        assert url.local?, 'local? should return true'
        assert !url.remote?, 'remote? should return false'
      else
        assert url.remote?, 'remote? should return true'
        assert !url.local?, 'local? should return false'
      end

      if tags.include? :ssh
        assert url.uses_ssh?, 'uses_ssh? should return true'
      else
        assert !url.uses_ssh?, 'uses_ssh? should return false'
      end

      if tags.include? :credentials
        assert url.has_credential?, 'has_credential? should return true'
      else
        assert !url.has_credential?, 'has_credential? should return false'
      end
    end
  end
end
