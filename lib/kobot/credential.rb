# frozen_string_literal: true

module Kobot
  # Credentials include id and password to login to KOT and
  # Gmail SMTP id and password to send email notifications.
  class Credential

    class << self
      attr_accessor :kot_id,
                    :kot_password,
                    :gmail_id,
                    :gmail_password

      # Make sure credentials are loaded by first checking
      # and reading from #{Config.credentials_file} if it
      # exists and then overriding any credentials if they
      # are also supplied as environment variables in ENV.
      #
      # If neither #{Config.credentials_file} nor ENV has
      # all the required credentials a command line prompt
      # will be displayed for users to input credentials
      # which will be saved to #{Config.credentials.file}
      # for later use.
      #
      # KOT id and password are required by default and
      # Gmail SMTP id and password are required only when
      # #{Config.gmail_notify_enabled} is true.
      def load!
        prompt_for_credentials until credentials_loaded
        @credentials.each do |attr, value|
          send("#{attr}=".to_sym, value)
        end
        Kobot.logger.info('Credentials load successful')
        Kobot.logger.debug(@credentials)
      end

      private

      def credentials_loaded
        @credentials ||= {}
        if File.exist? Config.credentials_file
          File.open(Config.credentials_file) do |file|
            file.each do |line|
              attr, value = line.strip.split('=')
              @credentials[attr] = value
            end
          end
        end
        required_credentials = %w[kot_id kot_password]
        required_credentials.concat %w[gmail_id gmail_password] if Config.gmail_notify_enabled
        required_credentials.each do |attr|
          if ENV[attr]
            Kobot.logger.warn(
              "[DEPRECATION] lower-case ENV variable is deprecated, please use #{attr.upcase} instead."
            )
          end
          env_attr_value = ENV[attr.upcase] || ENV[attr]
          @credentials[attr] = env_attr_value if env_attr_value
        end
        required_credentials.none? do |attr|
          credential = @credentials[attr]
          !credential || credential.strip.empty?
        end
      end

      def prompt_for_credentials
        puts 'Required credentials missing, please enter:'
        print 'kot_id: '
        kot_id_input = gets.chomp
        print 'kot_password: '
        kot_password_input = gets.chomp
        if Config.gmail_notify_enabled
          print 'gmail_id: '
          gmail_id_input = gets.chomp
          print 'gmail_password: '
          gmail_password_input = gets.chomp
        end
        File.open(Config.credentials_file, 'w+') do |file|
          file.puts "kot_id=#{kot_id_input}"
          file.puts "kot_password=#{kot_password_input}"
          if Config.gmail_notify_enabled
            file.puts "gmail_id=#{gmail_id_input}"
            file.puts "gmail_password=#{gmail_password_input}"
          end
        end
      end
    end
  end
end
