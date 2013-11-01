require_relative "./simplecov"
require 'test/unit'
require 'turn'

APP_CONFIG = {'nlm'=>{'ticket_url'=>'foo', 'api_url'=>'bar'}}

PROJECT_ROOT = File.expand_path("../../", __FILE__)
require File.join(PROJECT_ROOT, 'lib', 'bonnie_bundler')

def dump_db
  Mongoid.default_session.drop()
  FileUtils.rm_r 'db' if File.exists? 'db'
end
dump_db