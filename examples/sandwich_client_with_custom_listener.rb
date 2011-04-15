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

$total_jobs = 0

class SandwichListener < Cloudist::Listener
  listen_to "make.sandwich"
  
  before :find_command
  
  def find_command
    # puts "--- #{job_id}"
  end
  
  def progress(i)
    puts "Progress: %1d%" % i
  end
  
  def runtime(seconds)
    puts "#{job_id} Finished job in #{seconds} seconds"
    $total_jobs -= 1
    puts "--- #{$total_jobs} remaining"
  end
  
  def event(type)
    puts "Event: #{type}"
  end
  
  def finished
    # puts "*** Finished ***"
    if $total_jobs == 0
      # Cloudist.stop
    end
  end
  
  def reply
    p data
  end
  
end


Cloudist.signal_trap!

Cloudist.start(:logging => false, :heartbeat => 10) {
  puts "Started"
  unless ARGV.empty?
    job_count = ARGV.pop.to_i
    $total_jobs = job_count
    job_count.times { |i| 
      log.info("Dispatching sandwich making job...")
      enqueue('make.sandwich', {:bread => 'white', :sandwich_number => i})
    }
  end
  
  add_listener(SandwichListener)  
}
