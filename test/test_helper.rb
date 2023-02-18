
# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

if Redmine::VERSION::MAJOR < 4
  require File.expand_path('../../../../test/ui/base', __FILE__)

  class GitMirrorUITestCase < Redmine::UiTest::Base
    setup do
      Setting.delete_all
      Setting.clear_cache
      Capybara.current_driver = :chrome
    end

    teardown do
      Setting.delete_all
      Setting.clear_cache
    end
  end
else
  require File.expand_path('../../../../test/application_system_test_case', __FILE__)

  class GitMirrorUITestCase < ApplicationSystemTestCase
    driven_by :chrome
  end
end

class GitMirrorUITestCase
  setup do
    Capybara.app_host = "http://#{`hostname -i`.strip}:#{Capybara.server_port}"
  end

  def save_screenshoot()
    page.save_screenshot(File.expand_path('../_screenshot.png', __FILE__))
  end
end

options = Selenium::WebDriver::Chrome::Options.new(
  binary: ENV['CHROMIUM_BIN'] || "/usr/bin/google-chrome"
)

Capybara.register_driver :chrome do |app|
  options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1280,800')

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: options,
  )
end

Capybara.default_driver = :chrome
Capybara.javascript_driver = :chrome

Capybara.run_server = true
Capybara.server_host = '0.0.0.0'
Capybara.server_port ||= 31337
