# Cloudst Example: Sandwich Client
# 
# This example demonstrates dispatching a job to the worker and receiving event callbacks.
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
  
  log.info("Dispatching sandwich making job...")
  job = enqueue('make.sandwich', {:bread => 'white'})
  # enqueue('make.sandwich', {:bread => 'brown'})
  
  log.info("Queued job with ID: #{job.id}")
  
  # Listen to all sandwich jobs
  listen('make.sandwich') {
    everything {
      Cloudist.log.info("Job ID: #{job_id}")
    }
    
    progress {
      Cloudist.log.info("Progress: #{data[:progress]}")
    }
    
    event('started') {
      Cloudist.log.info("Started making sandwich at #{Time.now.to_s}")
    }
    
    event('finished'){
      Cloudist.log.info("Finished making sandwich at #{Time.now.to_s}")
    }
  }
  
}
