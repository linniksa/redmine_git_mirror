
module RedmineGitMirror
  module Ssh
    class << self
      def ensure_host_known(host)
        return unless host

        known_hosts = known_hosts_file

        o, status = Open3.capture2("ssh-keygen", "-F", host, "-f", known_hosts)
        if status.success?
          return if o.match /found/
        else
          # ssh-keygen fail if known_hosts file is not exists just log and continue
          puts "ssh-keygen exited with non-zero status: #{status}"
        end

        FileUtils.mkdir_p File.dirname(known_hosts), :mode => 0700

        o, status = Open3.capture2("ssh-keyscan", host)
        unless status.success?
          puts "ssh-keyscan exited with non-zero status: #{status}"
          return
        end

        puts "Adding #{host} to #{known_hosts}"
        File.open(known_hosts, 'a', 0600) do |file|
          file.puts o
        end
      end

      def command
        'ssh -o UserKnownHostsFile=' + known_hosts_file
      end

      private def known_hosts_file
        Dir.home + "/.ssh/known_hosts"
      end
    end
  end
end
