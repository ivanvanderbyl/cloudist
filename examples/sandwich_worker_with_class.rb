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
    log.info("Processing queue: #{queue.name}")
    log.info(data.inspect)
    
    job.started!
    (1..5).each do |i|
      job.progress(i * 20)
      # sleep(1)
      
      # raise ArgumentError, "NOT GOOD!" if i == 4
    end
    job.finished!
  end
end

Cloudist.signal_trap!

Cloudist.start(:heartbeat => 60, :logging => false) {
  Cloudist.handle('make.sandwich').with(SandwichWorker)
}
