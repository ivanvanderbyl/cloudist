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
  
  job('make.sandwich') {
    log.info("JOB (#{id}) Make sandwich with #{data[:bread]} bread")
    
    job.started!
    job.progress(0)
    job.progress(10)
    sleep(1)
    job.progress(20)
    sleep(5)
    job.progress(90)
    job.progress(100)
    job.finished!
  }
  
}
