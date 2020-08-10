# Kobot

Kobot is a simple tool to automate the clock in or clock out operation on the web service
provided by [KING OF TIME](kingtime.jp) by leveraging [Selenium WebDriver](selenium.dev),
and with Google Gmail service email notification can also be sent to notify the results.

It is meant for use only by one working under the discretionary labor system or flexible
hours where the daily record is still required regardless of the actual start or end time
of working, for example, software programmers or IT related engineers.

By being run in a periodic schedule system such as crontab, it eases the mental burden to
one for trying not to forget the clock action, as well as reduces the application process
for making up for the records when it was forgotten.

## Installation

#### Environment

Tested on macOS Catelina and runs on Heroku platform so it works on unix-like systems.

#### Configuration

By default it uses `~/.kobot` file locally to persist credentials for reuse, but all credentials
can be overridden by setting environment variables, which is the recommended way of running the
job on platforms like Heroku. When running for the first time, if none of the configuration file
and ENV satisfies all required credentials, an interactive prompt will be displayed for setting,
so there is no need to manually prepare the file beforehand. The content looks something like:
```property
kot_id=xxx
kot_password=xxx
```
Gmail account and password (or `app` password if MFA is on) are asked when notification is needed:
```property
gmail_id=xxx
gmail_password=xxx
```

#### Google Chrome browser

Make sure the latest version of Google Chrome is installed in system. On platforms like Heroku,
the [heroku-buildpack-google-chrome](https://elements.heroku.com/buildpacks/heroku/heroku-buildpack-google-chrome)
makes it extremely easy to get the browser ready.

#### Install the command line tool 

Make sure a modern version of Ruby is available and run command below to install:
```bash
$ gem install kobot
```

## Usage

Get help doc:
```bash
$ kobot -h
Usage: kobot [options]
    -c, --clock CLOCK                The clock action: in, out
    -l, --loglevel [LEVEL]           Specify log level: debug, info, warn, error. Default is info
    -s, --skip [D1,D2,D3]            Specify dates to skip clock in/out with date format YYYY-MM-DD and
                                     multiple values separated by comma, such as: 2020-05-01,2020-12-31
    -t, --to [TO]                    Email address to send notification to. By default it is sent to
                                     the same self email account used in SMTP config as the sender
    -n, --notify                     Enable email notification
    -d, --dryrun                     Run the process without actual clock in/out
    -x, --headless                   Start browser in headless mode
    -g, --geolocation                Allow browser to use geolocation
    -h, --help                       Show this help message
    -v, --version                    Show current version
```

Dryrun to try out:
```bash
$ kobot --clock in --dryrun
```

Clock in/out with email notification
```bash
$ kobot --clock in --notify
$ kobot --clock out --notify
```

Run the task with crontab
```cron
30 09 * * * user kobot --clock in --notify
30 18 * * * user kobot --clock out --notify
```
On platforms like Heroku, an add-on called [Heroku Scheduler](https://elements.heroku.com/addons/scheduler) makes
running scheduled tasks much easier. Tips: either clock in or clock out task can be scheduled multiple times in
case Scheduler misses to run due to Heroku system failures (which might occur very rarely in reality).

## Dependency

Kobot is an opinionated tool for which the only purpose is to get the tedious process automated, and therefore
Google Chrome is used as the supported browser and Google Gmail is chosen to be the email notification service
because both simply just work to get the job done. The [webdrivers](https://github.com/titusfortner/webdrivers)
gem is the only direct dependency and it is by intention to minimize the runtime gem dependency. 

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the
version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yuan-jiang/kobot.
This project is intended tobe a safe, welcoming space for collaboration, and contributors are
expected to adhere to the [code of conduct](https://github.com/yuan-jiang/kobot/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Kobot project's codebases, issue trackers, chat rooms and mailing lists is expected to
follow the [code of conduct](https://github.com/yuan-jiang/kobot/blob/master/CODE_OF_CONDUCT.md).
