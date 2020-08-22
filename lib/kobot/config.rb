# frozen_string_literal: true

module Kobot

  # Configuration definition includes static ones hardcoded and
  # dynamic ones that can be specified by command line options.
  class Config
    class << self
      attr_accessor :clock,
                    :loglevel,
                    :skip,
                    :dryrun,
                    :force

      attr_accessor :kot_url,
                    :kot_timezone_offset,
                    :kot_date_format

      attr_accessor :gmail_notify_enabled,
                    :gmail_notify_subject,
                    :gmail_notify_to,
                    :gmail_smtp_address,
                    :gmail_smtp_port

      attr_accessor :browser_headless,
                    :browser_geolocation,
                    :browser_wait_timeout

      attr_accessor :credentials_file

      def configure
        yield self
      end
    end
  end
end
