### v1.0.0
- Initial release

### v1.1.0
- Deprecated lower-case environment variables for credentials configuration
- Updated option help doc to indicate weekends and public holidays are skipped by default
- Updated required_ruby_version to be >= 2.4.0 to align with the webdrivers dependency

### v1.2.0
- Added an option to allow forcibly running regardless of weekends or public holidays
- Added an ENV flag to allow requiring lib in local workspace for development purpose

### v1.2.1
- Improved logging for better readability in logs
- Switched to builtin Logger#deprecate from Logger#warn for deprecations
- Renamed internal method to skip? from holiday? as it was meant for skipping any specified date

### v1.2.2
- Improved login screen wait and logging
- Applied fix for offenses about empty lines and long lines reported by Rubocop

### v1.2.3
- Improved validation logic to skip running due to weekend or intentional skips
- Refactored engine by reducing methods length based on reports by Rubocop
