
require 'uri'

module URI
  class GIT < Generic
    DEFAULT_PORT = 9418
  end
  @@schemes['GIT'] = GIT
end

module GitMirror
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
        @host = url.host
        @port = url.port
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

      if host.include? ('@')
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
      return false if scp_like?

      !password.to_s.empty? || !user.to_s.empty?
    end

    def normalize
      o = self.dup

      path = o.path.gsub(/\/{2,}/, '/')
      o.instance_variable_set(:@path, path)

      o.to_s
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
