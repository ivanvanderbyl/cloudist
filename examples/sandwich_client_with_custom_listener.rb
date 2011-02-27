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
  listen_to "make.sandwich", "eat.sandwich"
  
  before :find_command
  
  def find_command
    puts "--- #{job_id}"
  end
  
  def progress(i)
    puts "Progress: %1d%" % i
  end
  
  def runtime(seconds)
    puts "Finished job in #{seconds} seconds"
  end
  
  def event(type)
    puts "Event: #{type}"
  end
  
  def finished
    puts "*** Finished ***"
  end
  
  
  
end


Cloudist.signal_trap!

Cloudist.start(:logging => false, :heartbeat => 10) {
  
  unless ARGV.empty?
    job_count = ARGV.pop.to_i
    job_count.times { |i| 
      log.info("Dispatching sandwich making job...")
      enqueue('make.sandwich', {:bread => 'white', :sandwich_number => i})
    }
  end
  
  add_listener(SandwichListener)  
}
