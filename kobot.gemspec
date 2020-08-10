# frozen_string_literal: true

require_relative 'lib/kobot/version'

Gem::Specification.new do |spec|
  spec.name                          = 'kobot'
  spec.version                       = Kobot::VERSION
  spec.authors                       = ['Andy Jiang']
  spec.email                         = ['yuanjiang@outlook.com']

  spec.summary                       = 'Kobot automates the clock in/out of KING OF TIME.'
  spec.description                   = <<-DESC
    Kobot is a simple tool to automate the clock in or clock out operation on the web service
    provided by [KING OF TIME](kingtime.jp) by leveraging [Selenium WebDriver](selenium.dev),
    and with Google Gmail service email notification can also be sent to notify the results.
  DESC

  spec.homepage                      = 'https://github.com/yuan-jiang/kobot'
  spec.license                       = 'MIT'
  spec.required_ruby_version         = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org/'
  spec.metadata['homepage_uri']      = spec.homepage
  spec.metadata['source_code_uri']   = 'https://github.com/yuan-jiang/kobot'
  spec.metadata['changelog_uri']     = 'https://github.com/yuan-jiang/kobot/blob/master/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files                         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir                        = 'exe'
  spec.executables                   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths                 = ['lib']

  spec.add_runtime_dependency 'webdrivers', '~> 4.0'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
