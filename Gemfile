source "http://rubygems.org"
gemspec

gem 'health-data-standards', :git => 'https://github.com/projectcypress/health-data-standards.git', :branch => 'master'
gem 'quality-measure-engine', :git => 'https://github.com/pophealth/quality-measure-engine.git', :branch => 'mongoid_refactor'

gem 'hqmf2js', '1.3.0'
#gem 'hqmf2js', :git => 'https://github.com/pophealth/hqmf2js.git', :branch => 'master'

gem 'hquery-patient-api', '1.0.4'

gem 'rails', '3.2.14'
gem 'rake'
gem 'pry'
gem 'tilt'
gem 'coffee-script'
gem 'sprockets'
gem "therubyracer", :require => 'v8'
gem 'mongoid'
gem 'rubyzip', '< 1.0.0'

# needed for parsing value sets (we need to use roo rather than rubyxl because the value sets are in xls rather than xlsx)
gem 'roo'

group :test do
  gem 'simplecov', :require => false

  gem 'minitest', "~> 4.0"
  gem 'turn', :require => false
  gem 'awesome_print', :require => 'ap'
end

