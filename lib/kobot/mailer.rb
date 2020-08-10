# frozen_string_literal: true

require 'net/smtp'

module Kobot

  # Responsible for sending email notifications in SMTP with Gmail
  class Mailer
    class << self

      # Sends email in preconfigured Gmail SMTP credential and to the recipient
      # configured by #{Config.gmail_notify_to} or self if not configured, with
      # email subject set by #{Config.gmail_notify_subject}.
      #
      # Whether the email is actually sent or not is dependent on the value of
      # #{Config.gmail_notify_enabled}, and when it is set to false, the email
      # message will be printed in logging instead.
      #
      # @param body The email message body to send
      def send(body)
        from = Credential.gmail_id
        to = Config.gmail_notify_to || from
        subject = Config.gmail_notify_subject
        message = compose(from, to, subject, body)
        unless Config.gmail_notify_enabled
          Kobot.logger.info "This email notification would have been sent:\n#{message}"
          return
        end
        smtp = Net::SMTP.new(
          Config.gmail_smtp_address,
          Config.gmail_smtp_port
        )
        smtp.enable_starttls_auto
        smtp.start(
          'localhost',
          Credential.gmail_id,
          Credential.gmail_password,
          :plain
        ) do
          smtp.send_message message, from, to
        end
      end

      private

      def compose(from, to, subject, body)
        <<~END_OF_MESSAGE
          From: <#{from}>
          To: <#{to}>
          MIME-Version: 1.0
          Content-type: text/html
          Subject: #{subject} 
          Date: #{Time.now.getlocal(Config.kot_timezone_offset)}

          #{body}
        END_OF_MESSAGE
      end
    end
  end
end
