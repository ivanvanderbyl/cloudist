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
  enqueue('make.sandwich', {:bread => 'white'})
  
  # Listen to all sandwich jobs
  listen('make.sandwich') {
    Cloudist.log.info("Make sandwich event: #{data[:event]}")
    Cloudist.log.debug(data.inspect)
  }
  
}
