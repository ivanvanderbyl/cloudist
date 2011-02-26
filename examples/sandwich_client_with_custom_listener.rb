# Cloudst Example: Sandwich Client with custom listener class
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


class SandwichListener < Cloudist::Listener
  listen_to "make.sandwich"
  
end


Cloudist.signal_trap!

Cloudist.start {
  
  log.info("Dispatching sandwich making job...")
  
  unless ARGV.empty?
    job_count = ARGV.pop.to_i
    job_count.times { |i| enqueue('make.sandwich', {:bread => 'white', :sandwich_number => i})}
  end
  
  add_listener(SandwichListener)  
}
