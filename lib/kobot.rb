# frozen_string_literal: true

require 'kobot/version'
require 'kobot/exception'
require 'kobot/option'
require 'kobot/config'
require 'kobot/credential'
require 'kobot/logger'
require 'kobot/mailer'
require 'kobot/engine'

# Kobot is a simple tool to automate the clock in or clock out operation on the web service
# provided by [KING OF TIME](kingtime.jp) by leveraging [Selenium WebDriver](selenium.dev),
# and with Google Gmail service email notification can also be sent to notify the results.
module Kobot
  class << self

    # The entrance to run Kobot.
    def run
      configure
      Engine.new.start
    rescue StandardError => e
      logger.error e.message
      logger.error e.backtrace
      Mailer.send e.message
    end

    # Parses command line options, configures Kobot, and finally ensures
    # required credentials are loaded properly and ready to be in use.
    def configure
      options = Option.parse!
      Config.configure do |config|
        config.clock                 = options[:clock].to_sym
        config.loglevel              = options[:loglevel]&.to_sym || :info
        config.dryrun                = options[:dryrun]
        config.skip                  = options[:skip] || []

        config.kot_url               = 'https://s2.kingtime.jp/independent/recorder/personal/'
        config.kot_timezone_offset   = '+09:00'
        config.kot_date_format       = '%m/%d'

        config.gmail_notify_enabled  = options[:notify]
        config.gmail_notify_to       = options[:to]
        config.gmail_notify_subject  = "[#{Module.nesting.last}] Notification"
        config.gmail_smtp_address    = 'smtp.gmail.com'
        config.gmail_smtp_port       = 587

        config.browser_headless      = options[:headless]
        config.browser_geolocation   = options[:geolocation]
        config.browser_wait_timeout  = 10

        config.credentials_file      = File.join(Dir.home, ".#{File.basename(__FILE__, File.extname(__FILE__))}")
      end
      Credential.load!
    end

    def logger
      @logger ||= Logger.new
    end
  end
end
