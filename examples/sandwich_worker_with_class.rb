# Cloudst Example: Sandwich Worker
# 
# This example demonstrates receiving a job and sending back events to the client to let it know we've started and finsihed
# making a sandwich. From here you could dispatch an eat.sandwich event.
# 
# Be sure to update the Cloudist connection settings if they differ from defaults:
# user: guest
# pass: guest
# port: 5672
# host: localhost
# vhost: /
# 
$:.unshift File.dirname(__FILE__) + '/../lib'
require "rubygems"
require "cloudist"

class SandwichWorker < Cloudist::Worker
  def process
    log.info("Processing #{queue.name} job: #{id}")
    
    # This will trigger the start event
    # Appending ! to the end of a method will trigger an
    # event reply with its name
    # 
    # e.g. job.working!
    # 
    job.started!
    
    (1..5).each do |i|
      # This sends a progress reply, you could use this to
      # update a progress bar in your UI
      # 
      # usage: #progress([INTEGER 0 - 100])
      job.progress(i * 20)
      
      # Work hard!
      sleep(1)
      
      # Uncomment this to test error handling in Listener
      # raise ArgumentError, "NOT GOOD!" if i == 4
    end
    
    # Trigger finished event
    job.finished!
  end
end

Cloudist.signal_trap!

Cloudist.start(:logging => false) {
  Cloudist.handle('make.sandwich').with(SandwichWorker)
}
