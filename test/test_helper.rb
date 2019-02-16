
# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

if Redmine::VERSION::MAJOR < 4
  require File.expand_path('../../../../test/ui/base', __FILE__)

  class GitMirrorUITestCase < Redmine::UiTest::Base
    def self.driven_by(name, *cmd)
      Capybara.current_driver = name
    end

    setup do
      Setting.delete_all
      Setting.clear_cache
    end

    teardown do
      Setting.delete_all
      Setting.clear_cache
    end
  end
else
  require File.expand_path('../../../../test/application_system_test_case', __FILE__)

  class GitMirrorUITestCase < ApplicationSystemTestCase
  end
end

class GitMirrorUITestCase
  driven_by :chrome

  setup do
    Capybara.app_host = "http://#{`hostname -i`.strip}:#{Capybara.server_port}"
  end
end

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app,
    :browser => :remote,
    :desired_capabilities => :chrome,
    :url => "http://selenium:4444/wd/hub"
  )
end

Capybara.run_server = true
Capybara.server_host = '0.0.0.0'
Capybara.server_port ||= 31337
