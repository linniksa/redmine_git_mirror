
require 'uri'

module URI
  class GIT < Generic
    DEFAULT_PORT = 9418
  end
  @@schemes['GIT'] = GIT
end

module RedmineGitMirror
  class URL
    attr_reader :scheme, :user, :password, :host, :port, :path

    private def initialize(url)
      url = url.to_s
      raise 'Empty url' if url.empty?

      begin
        url = URI.parse(url)

        @scheme = url.scheme
        @user = url.user
        @password = url.password
        @host = url.host unless url.host.to_s.empty?
        @port = url.port
        @default_port = url.default_port
        @path = url.path

        return
      rescue
      end

      host, path = url.to_s.split(':', 2)
      if host.length == 1 && path[0] == '\\'
        #local windows path
        @path = url
        return
      end

      if host.length > 0 && path.length > 0
        return if parse_scp_like_url(host, path)
      end

      raise 'Unknown git remote url'
    end

    private def parse_scp_like_url(host, path)
      return if !path || path.include?(':') || path[0] == '/'

      if host.include? '@'
        user, host = host.split('@', 2)

        return if user.length <= 0
        return if host.include?('@')

        @user = user
        @host = host
      else
        @host = host
      end

      @path = '/' + path
    end

    def remote?
      !self.local?
    end

    def local?
      (@scheme.nil? && !scp_like?) || @scheme == "file"
    end

    def scp_like?
      @scheme.nil? && !@host.nil?
    end

    def uses_ssh?
      @scheme == 'ssh' || self.scp_like?
    end

    def scheme?(*schemes)
      schemes.include?(self.scp_like? ? 'scp' : self.scheme)
    end

    def has_credential?
      return false if uses_ssh? && password.nil?

      !password.nil? || !user.nil?
    end

    def normalize
      o = self.dup

      path = o.path.gsub(/\/{2,}/, '/')
      o.instance_variable_set(:@path, path)

      o.to_s
    end

    def vary(all: false)
      schemes = %w[http https ssh scp]
      http_schemes = %w[http https]
      ssh_schemes = %w[ssh scp]

      current_scheme = self.scp_like?? 'scp' : self.scheme

      unless all
        if http_schemes.include?(current_scheme)
          schemes = http_schemes
        elsif ssh_schemes.include?(current_scheme)
          schemes = ssh_schemes
        else
          schemes = [current_scheme]
        end
      end

      rez = []
      schemes.each do |scheme|
        s = to_scheme(scheme)
        rez.concat(s.vary_suffix('.git'))
      end

      rez
    end

    def vary_suffix(suffix)
      return self.dup unless path

      [
        to_suffix(suffix, present: false).to_s,
        to_suffix(suffix, present: true).to_s
      ]
    end

    private def to_scheme(scheme)
      n = self.dup
      if scheme == 'scp'
        return n if self.scp_like?

        n.instance_variable_set(:@user, 'git') unless n.user
        n.instance_variable_set(:@scheme, nil)

        return n
      elsif scheme == 'ssh'
        n.instance_variable_set(:@user, 'git') unless n.user
      end

      n.instance_variable_set(:@scheme, scheme)
      if self.scp_like?
        n.instance_variable_set(:@user, nil) unless %w[ssh scp].include? scheme
      end

      n
    end

    private def to_suffix(suffix, present: )
      n = self.dup
      return n unless path

      if present && !path.end_with?(suffix)
        n.instance_variable_set(:@path, path + suffix)
      elsif !present
        n.instance_variable_set(:@path, path.chomp(suffix))
      end

      n
    end

    def to_h
      rez = {}
      rez[:scheme] = @scheme if @scheme
      rez[:user] = @user if @user
      rez[:password] = @password if @password
      rez[:host] = @host if @host
      rez[:port] = @port if @port
      rez[:path] = @path if @path
      rez
    end

    def to_s
      s = StringIO.new

      if @scheme
        s << @scheme
        s << '://'

        if @user
          s << @user
          if @password
            s << ':'
            s << @password
          end
          s << '@'
        end

        s << @host
        if @port and @port != @default_port
          s << ':'
          s << @port
        end
        s << path
      elsif @host
        if @user
          s << @user
          s << '@'
        end

        s << host
        s << ':'
        s << path[1..-1]
      else
        return path
      end

      s.string
    end

    class << self
      def parse(url)
        return url if url.is_a? self

        self.new(url.to_s)
      end
    end
  end
end
