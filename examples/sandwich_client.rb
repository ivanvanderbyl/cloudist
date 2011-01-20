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
  
  unless ARGV.empty?
    job_count = ARGV.pop.to_i
    job_count.times { |i| enqueue('make.sandwich', {:bread => 'white', :sandwich_number => i})}
  end
  
  
  # enqueue('eat.sandwich', {:sandwich => job.id})
  # enqueue('make.sandwich', {:bread => 'brown'})
    
  # Listen to all sandwich jobs
  listen('make.sandwich', 'eat.sandwich') {
    everything {
      Cloudist.log.info("#{headers[:message_type]} - Job ID: #{job_id}")
    }
    
    error { |e|
      Cloudist.log.error(e.inspect)
      Cloudist.log.error(e.backtrace.inspect)
      Cloudist.stop
    }
    
    progress {
      Cloudist.log.info("Progress: #{data[:progress]}")
    }
    
    event('started') {
      Cloudist.log.info("Started making sandwich at #{Time.now.to_s}")
    }
    
    event('finished'){
      Cloudist.log.info("Finished making sandwich at #{Time.now.to_s}")
      Cloudist.stop
    }
  }
  
}
