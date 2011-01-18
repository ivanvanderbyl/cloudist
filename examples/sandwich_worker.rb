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

Cloudist.signal_trap!

Cloudist.start {
  log.info("Started Worker")
  
  worker {
    job('make.sandwich') {
      # Fire the started event
      
      log.info("JOB (#{id}) Make sandwich with #{data[:bread]} bread")
      log.debug(data.inspect)
      
      EM.defer {
        started!
        sleep(5)
        finished!
      }
    }    
  }
}
