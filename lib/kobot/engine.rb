# frozen_string_literal: true

require 'webdrivers/chromedriver'

module Kobot
  # The core class that launches browser, logins to KOT, reads today
  # record, and conducts clock in or clock out action based on config.
  class Engine
    def initialize
      @now = Time.now.getlocal(Config.kot_timezone_offset)
      @today = @now.strftime(Config.kot_date_format)
      @top_url = Config.kot_url
    end

    # The entrance where the whole flow starts.
    #
    # It exits early if today is weekend or marked as to skip by
    # the #{Config.skip} specified from command line option --skip.
    #
    # Unexpected behavior such as record appearing as holiday on
    # the web or failure of clock in/out action is handled within
    # the method by logging and/or email notifications if enabled.
    #
    # System errors or any unknown exceptions occurred if any are
    # to be popped up and should be handled by the outside caller.
    def start
      return unless should_run_today?

      launch_browser
      login
      read_today_record
      validate_today_record!
      if Config.clock == :in
        clock_in!
      else
        clock_out!
      end
      logout
    rescue KotRecordError => e
      Kobot.logger.warn(e.message)
      Mailer.send(clock_notify_message(status: e.message))
      logout
    rescue KotClockInError => e
      Kobot.logger.warn e.message
      Mailer.send(clock_notify_message(clock: :in, status: e.message))
      logout
    rescue KotClockOutError => e
      Kobot.logger.warn e.message
      Mailer.send(clock_notify_message(clock: :out, status: e.message))
      logout
    rescue StandardError => e
      Kobot.logger.error(e.message)
      Kobot.logger.error(e.backtrace)
      Mailer.send(clock_notify_message(status: e.message))
      logout
    ensure
      close_browser
    end

    private

    def should_run_today?
      if skip?
        Kobot.logger.warn("Today=#{@today} is skipped as per: --skip=#{Config.skip}")
        return false
      end
      return true unless weekend?

      Kobot.logger.info("[Force] should have exited: today=#{@today} is weekend") if Config.force
      Kobot.logger.warn("Today=#{@today} is weekend") unless Config.force
      Config.force
    end

    def launch_browser
      prefs = {
        profile: {
          default_content_settings: {
            geolocation: Config.browser_geolocation ? 1 : 2
          }
        }
      }
      options = Selenium::WebDriver::Chrome::Options.new(prefs: prefs)
      options.headless! if Config.browser_headless
      @browser = Selenium::WebDriver.for(:chrome, options: options)
      @wait = Selenium::WebDriver::Wait.new(timeout: Config.browser_wait_timeout)
      Kobot.logger.info('Launch browser successful')
    end

    def close_browser
      return unless @browser

      Kobot.logger.info('Close browser')
      @browser.quit
    end

    def login
      Kobot.logger.info("Navigate to: #{@top_url}")
      @browser.get @top_url
      @wait.until { @browser.find_element(id: 'modal_window') }
      Kobot.logger.info "Page title: #{@browser.title}"
      Kobot.logger.debug do
        "Login with id=#{Credential.kot_id} and password=#{Credential.kot_password}"
      end
      @browser.find_element(id: 'id').send_keys Credential.kot_id
      @browser.find_element(id: 'password').send_keys Credential.kot_password
      @browser.find_element(css: 'div.btn-control-message').click

      Kobot.logger.info 'Login successful'
      @wait.until { @browser.find_element(id: 'notification_content').text.include?('データを取得しました') }
      if Config.browser_geolocation
        begin
          @wait.until { @browser.find_element(id: 'location_area').text.include?('位置情報取得済み') }
        rescue StandardError => e
          Kobot.logger.warn "Get geolocation failed: #{e.message}"
        end
      end
      Kobot.logger.info "Page title: #{@browser.title}"
    end

    def logout
      if @browser.current_url.include? 'admin'
        Kobot.logger.info('Logout from タイムカード page')
        @browser.find_element(css: 'div.htBlock-header_logoutButton').click
      else
        Kobot.logger.info('Logout from Myレコーダー page')
        @wait.until { @browser.find_element(id: 'menu_icon') }.click
        @wait.until { @browser.find_element(link: 'ログアウト') }.click
        @browser.switch_to.alert.accept
      end
      Kobot.logger.info 'Logout successful'
    end

    def read_today_record
      Kobot.logger.info('Navigate to タイムカード page')
      @wait.until { @browser.find_element(id: 'menu_icon') }.click
      @wait.until { @browser.find_element(link: 'タイムカード') }.click

      time_table = @wait.until { @browser.find_element(css: 'div.htBlock-adjastableTableF_inner > table') }
      time_table.find_elements(css: 'tbody > tr').each do |tr|
        date_cell = tr.find_element(css: 'td.htBlock-scrollTable_day')
        next unless date_cell.text.include? @today

        Kobot.logger.info('Reading today record')
        @kot_today = date_cell.text
        @kot_today_css_class = date_cell.attribute('class')
        @kot_today_type = tr.find_element(css: 'td.work_day_type').text
        @kot_today_clock_in = tr.find_element(
          css: 'td.start_end_timerecord[data-ht-sort-index="START_TIMERECORD"]'
        ).text
        @kot_today_clock_out = tr.find_element(
          css: 'td.start_end_timerecord[data-ht-sort-index="END_TIMERECORD"]'
        ).text
        Kobot.logger.debug do
          {
            kot_toay: @kot_today,
            kot_today_css_class: @kot_today_css_class,
            kot_today_type: @kot_today_type,
            kot_today_clock_in: @kot_today_clock_in,
            kot_today_clock_out: @kot_today_clock_out
          }
        end
        break
      end
    end

    def validate_today_record!
      raise KotRecordError, "Today=#{@today} is not found on kot" if @kot_today.strip.empty?

      if kot_weekend?
        raise KotRecordError, "Today=#{@today} is marked as weekend on kot: #{@kot_today}" unless Config.force

        Kobot.logger.info(
          "[Force] should have exited: today=#{@today} is marked as weekend on kot: #{@kot_today}"
        )
      end

      return unless kot_public_holiday?
      raise KotRecordError, "Today=#{@today} is marked as public holiday on kot: #{@kot_today}" unless Config.force

      Kobot.logger.info(
        "[Force] should have exited: today=#{@today} is marked as public holiday on kot: #{@kot_today}"
      )
    end

    def clock_in!
      Kobot.logger.warn("Clock in during the afternoon: #{@now}") if @now.hour > 12
      if @kot_today_clock_in.strip.empty?
        click_clock_in_button
        return if Config.dryrun

        read_today_record
        raise KotClockInError, 'Clock in operation seems to have failed' if @kot_today_clock_in.strip.empty?

        Kobot.logger.info("Clock in successful: #{@kot_today_clock_in}")
        Mailer.send(clock_notify_message(clock: :in))
      else
        Kobot.logger.warn("Clock in done already: #{@kot_today_clock_in}")
      end
    end

    def clock_out!
      Kobot.logger.warn("Clock out during the morning: #{@now}") if @now.hour <= 12
      unless Config.dryrun
        if @kot_today_clock_in.strip.empty?
          raise KotClockOutError,
                "!!!No clock in record for today=#{@kot_today}!!!"
        end
      end

      if @kot_today_clock_out.strip.empty?
        click_clock_out_button
        return if Config.dryrun

        read_today_record
        raise KotClockOutError, 'Clock out operation seems to have failed' if @kot_today_clock_out.strip.empty?

        Kobot.logger.info("Clock out successful: #{@kot_today_clock_out}")
        Mailer.send(clock_notify_message(clock: :out))
      else
        Kobot.logger.warn("Clock out done already: #{@kot_today_clock_out}")
      end
    end

    def click_clock_in_button
      Kobot.logger.info("Navigate to: #{@top_url}")
      @browser.get @top_url
      clock_in_button = @wait.until { @browser.find_element(css: 'div.record-clock-in') }
      if Config.dryrun
        Kobot.logger.info('[Dryrun] clock in button (出勤) would have been clicked')
      else
        Kobot.logger.info('Clicking the clock in button (出勤)')
        clock_in_button.click
      end
    end

    def click_clock_out_button
      Kobot.logger.info("Navigate to: #{@top_url}")
      @browser.get @top_url
      clock_out_button = @wait.until { @browser.find_element(css: 'div.record-clock-out') }
      if Config.dryrun
        Kobot.logger.info('[Dryrun] clock out button (退勤) would have been clicked')
      else
        Kobot.logger.info('Clicking the clock in button (退勤)')
        clock_out_button.click
      end
    end

    def weekend?
      @now.saturday? || @now.sunday?
    end

    def skip?
      return false unless Config.skip
      return false unless Config.skip.respond_to? :include?

      Config.skip.include? @now.strftime('%F')
    end

    def kot_weekend?
      %w[土 日].any? { |kanji| @kot_today&.include? kanji }
    end

    def kot_public_holiday?
      return true if @kot_today_type&.include? '休日'

      kot_today_highlighted = %w[sunday saturday].any? do |css|
        @kot_today_css_class&.include? css
      end
      if kot_today_highlighted
        Kobot.logger.warn(
          "Today=#{@kot_today} is highlighted (holiday) but not marked as 休日"
        )
      end
      kot_today_highlighted
    end

    def clock_notify_message(clock: nil, status: :success)
      color = status == :success ? 'green' : 'red'
      message = [
        "<b>Date:</b> #{@today}",
        "<b>Status:</b> <span style='color:#{color}'>#{status}</span>"
      ]
      message << "<b>Clock_in:</b> #{@kot_today_clock_in}" if clock
      message << "<b>Clock_out:</b> #{@kot_today_clock_out}" if clock == :out
      message.join('<br>')
    end
  end
end
