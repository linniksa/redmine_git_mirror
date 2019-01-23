
module GitMirror
  module SSH
    def self.ensure_host_known(host)
      return unless host

      o, status = Open3.capture2("ssh-keygen", "-F", host)
      if status.success?
        return if o.match /found/
      else
        # ssh-keygen fail if known_hosts file is not exists just log and continue
        puts "ssh-keygen exited with non-zero status: #{status}"
      end

      known_hosts = Dir.home + "/.ssh/known_hosts"

      FileUtils.mkdir_p File.dirname(known_hosts)

      o, status = Open3.capture2("ssh-keyscan", host)
      unless status.success?
        puts "ssh-keyscan exited with non-zero status: #{status}"
        return
      end

      puts "Adding #{host} to #{known_hosts}"
      Kernel::open(known_hosts, 'a') do |file|
        file.puts o
      end
    end
  end
end
