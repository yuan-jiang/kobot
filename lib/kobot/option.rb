# frozen_string_literal: true

require 'optparse'

module Kobot
  # Responsible for parsing the command line options for custom execution.
  class Option
    class << self
      # Parses command line options and returns a hash containing the options.
      def parse!
        options = {}
        opt_parser = OptionParser.new do |opt|
          opt.banner = "Usage: #{$PROGRAM_NAME} [options]"

          opt.on('-c', '--clock CLOCK', 'Required; the clock action option: in, out') do |clock|
            options[:clock] = clock
          end

          opt.on('-l', '--loglevel [LEVEL]', 'Specify log level: debug, info, warn, error; default is info') do |level|
            options[:loglevel] = level
          end

          opt.on('-s', '--skip [D1,D2,D3]', Array,
                 'Specify dates to skip clock in/out with date format YYYY-MM-DD and',
                 'multiple values separated by comma, such as: 2020-05-01,2020-12-31;',
                 'weekends and public holidays in Japan will be skipped by default') do |skip|
            options[:skip] = skip
          end

          opt.on('-t', '--to [TO]',
                 'Email address to send notification to; by default it is sent to',
                 'the same self email account used in SMTP config as the sender') do |to|
            options[:to] = to
          end

          opt.on('-n', '--notify', 'Enable email notification') do |notify|
            options[:notify] = notify
          end

          opt.on('-d', '--dryrun', 'Run the process without actual clock in/out') do |dryrun|
            options[:dryrun] = dryrun
          end

          opt.on('-f', '--force',
                 'Run the process forcibly regardless of weekends or public holidays;',
                 'must be used together with --dryrun to prevent mistaken operations') do |force|
            options[:force] = force
          end

          opt.on('-x', '--headless', 'Start browser in headless mode') do |headless|
            options[:headless] = headless
          end

          opt.on('-g', '--geolocation', 'Allow browser to use geolocation') do |geolocation|
            options[:geolocation] = geolocation
          end

          opt.on_tail('-h', '--help', 'Show this help message') do
            puts opt
            exit 0
          end

          opt.on_tail('-v', '--version', 'Show current version') do
            puts VERSION
            exit 0
          end
        end
        opt_parser.parse! ARGV
        raise OptionParser::MissingArgument, 'The clock option is required' if options[:clock].nil?
        unless %w[in out].include? options[:clock]
          raise OptionParser::InvalidArgument, 'The clock option must be either: in, out'
        end
        if options[:force] && !options[:dryrun]
          raise OptionParser::InvalidArgument, 'Must specify --dryrun for forcibly running'
        end

        options
      rescue OptionParser::MissingArgument, OptionParser::InvalidArgument => e
        puts e
        puts opt_parser.help
        exit 1
      end
    end
  end
end
