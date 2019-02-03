
module GitMirror
  module Settings
    class << self
      def path
        File.expand_path(File.dirname(__FILE__) + '/../../repos/')
      end

      def allowed_schemes
        settings[:schemes] || []
      end

      private def settings
        s = Setting[:plugin_redmine_git_mirror]
        return s if s.is_a? Hash

        {}
      end
    end
  end
end
