require 'rubygems'
require 'bundler/setup'

require 'active_record'
require_relative "../settings"

filename = './schema.rb'

ActiveRecord::Base.establish_connection(Settings::DB)


File.open(filename, "w:utf-8") do |file|
  ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
end
