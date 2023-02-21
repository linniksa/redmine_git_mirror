
require 'singleton'

module RedmineGitMirror
  module Settings
    DEFAULT = {
      :schemes => %w[http https scp],
      :url_change_allowed => false,
      :prevent_multiple_clones => true,
      :search_clones_in_all_schemes => true,
      :branches_to_fetch_change_allowed => true,
    }.freeze

    class << self
      def path
        File.expand_path(File.dirname(__FILE__) + '/../../repos/')
      end

      def allowed_schemes
        self[:schemes] || []
      end

      def url_change_allowed?
        s = self[:url_change_allowed] || false

        s == true || s.to_s == '1'
      end

      def prevent_multiple_clones?
        s = self[:prevent_multiple_clones] || false

        s == true || s.to_s == '1'
      end

      def search_clones_in_all_schemes?
        s = self[:search_clones_in_all_schemes] || false

        s == true || s.to_s == '1'
      end

      def branches_to_fetch_change_allowed?
        s = self[:branches_to_fetch_change_allowed] || false

        s == true || s.to_s == '1'
      end

      def remove_unreachable_on_fetch?
        s = self[:remove_unreachable_on_fetch] || false

        s == true || s.to_s == '1'
      end

      private def [](key)
        key = key.intern if key.is_a?(String)
        settings = Setting[:plugin_redmine_git_mirror] || {}

        return settings[key] if settings.key?(key)
        return settings[key.to_s] if settings.key?(key.to_s)

        DEFAULT[key]
      end
    end
  end
end
