# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
set :output, "/home/rh/whenever_cron.log"

require "./config/initializers/tcal_constants.rb"

# every AUTO_SYNC_SETTINGS[:cron_interval], roles: [:app] do
#   runner("User.enqueue_auto_syncs")
# end

every INTERCOM_SYNC_INTERVAL, roles: [:app] do
  runner("IntercomSync.new.sync_recently_changed_users")
end

every 23.hours, roles: [:app] do
  runner "TcdStaffScrape.new.do_it!"
end

# Learn more: http://github.com/javan/whenever
