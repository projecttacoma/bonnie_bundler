require_relative "./simplecov"
require 'test/unit'
require 'turn'
require 'rails'
require 'hquery-patient-api'
APP_CONFIG = {'nlm'=>{'ticket_url'=>'foo', 'api_url'=>'bar'}}

PROJECT_ROOT = File.expand_path("../../", __FILE__)
require File.join(PROJECT_ROOT, 'lib', 'bonnie_bundler')
BonnieBundler.logger = Log4r::Logger.new("Bonnie Bundler")
BonnieBundler.logger.outputters = Log4r::Outputter.stdout

def dump_db
  Mongoid.default_session.drop()
  FileUtils.rm_r 'db' if File.exists? 'db'
end
dump_db