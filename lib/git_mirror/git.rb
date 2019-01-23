
module GitMirror
  class Git
    class << self
      GIT_BIN = Redmine::Configuration['scm_git_command'] || 'git'

      def check_remote_url(url)
        url = GitMirror::URL.parse(url)
        GitMirror::SSH.ensure_host_known(url.host) if url.uses_ssh?

        _, e = git 'ls-remote',  '-h', url.to_s, 'master'
        e
      end

      def init(clone_path, url)
        url = GitMirror::URL.parse(url)
        GitMirror::SSH.ensure_host_known(url.host) if url.uses_ssh?

        if Dir.exists? clone_path
          o, e = git "--git-dir", clone_path, "config", "--get", "remote.origin.url"
          return e if e

          return "#{clone_path} remote url differs" unless o == url.to_s
        else
          _, e = git "init", "--bare", clone_path
          return e if e

          _, e = git "--git-dir", clone_path, "remote", "add", "origin", url.to_s
          return e if e
        end

        set_fetch_refs(clone_path, [
          '+refs/heads/*:refs/heads/*',
          '+refs/tags/*:refs/tags/*',
        ])
      end

      private def set_fetch_refs(clone_path, configs)
        o, e = git "--git-dir", clone_path, "config", "--get-all", "remote.origin.fetch"
        return e if e

        # special ref that removes all refs outside specified
        expected = ["+__-=_=-__/*:refs/*"] + configs

        if o && o.lines
          actual = o.lines.map(&:strip)
          return if expected.eql?(actual)
        end

        # need change
        _, e = git "--git-dir", clone_path, "config", "--unset-all", "remote.origin.fetch"
        return e if e

        expected.each do |v|
          _, e = git "--git-dir", clone_path, "config", "--add", "remote.origin.fetch", v
          return e if e
        end

        nil
      end

      def fetch(clone_path, url)
        e = GitMirror::Git.init(clone_path, url)
        return e if e

        _, e = git "--git-dir", clone_path, "fetch", "--prune", "--all"
        e
      end

      private def git(*cmd)
        s, e, status = Open3.capture3(GIT_BIN, *cmd)
        s.to_s.strip!

        return s, nil if status.success?

        e.to_s.strip!

        if e.lines.first
          e = e.lines.first.strip.truncate(100)
        else
          e = e.truncate(100)
        end

        e = e || "git exit with status #{status}"

        return s, e
      end
    end
  end
end
