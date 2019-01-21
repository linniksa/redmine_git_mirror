
module GitMirror
  module Settings
    def self.path
      File.expand_path(File.dirname(__FILE__) + '/../../repo/')
    end
  end
end
