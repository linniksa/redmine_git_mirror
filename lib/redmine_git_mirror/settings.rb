
module RedmineGitMirror
  module Settings
    class << self
      def path
        File.expand_path(File.dirname(__FILE__) + '/../../repos/')
      end

      def allowed_schemes
        settings[:schemes] || []
      end

      def url_change_allowed?
        s = settings[:url_change_allowed] || false

        s == true || s.to_s == '1'
      end

      def prevent_multiple_clones?
        s = settings[:prevent_multiple_clones] || false

        s == true || s.to_s == '1'
      end

      def search_clones_in_all_schemes?
        s = settings[:search_clones_in_all_schemes] || false

        s == true || s.to_s == '1'
      end

      private def settings
        s = Setting[:plugin_redmine_git_mirror]
        return s if s.is_a? Hash

        {}
      end
    end
  end
end
