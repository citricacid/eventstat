require 'rubygems'
require 'bundler/setup'

require 'date'
require_relative "settings"
require_relative 'models/models'

# Mini-script to update locks on all branches to the end of previous month
# Suitable for a monthly cron job


ActiveRecord::Base.establish_connection(Settings::DB)

date = Date.today.beginning_of_month.prev_day

Branch.all.each do |branch|
    branch.set_lock(date)
end
