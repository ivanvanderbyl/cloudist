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
  
  before :find_job
  
  def find_job
    puts "--- #{payload.id}"
  end
  
  def progress(i)
    puts "Progress: %1d%" % i
  end
  
  def runtime(seconds)
    puts "#{id} Finished job in #{seconds} seconds"
    $total_jobs -= 1
    puts "--- #{$total_jobs} jobs remaining"
  end
  
  # def started
  #   puts "Started"
  # end

  def event(type)
    puts "Event: #{type}"
  end
  
  def finished
    puts "*** Finished ***"
    
    if $total_jobs == 0
      puts "Completed all jobs"
      Cloudist.stop
    end
  end
  
  # def reply
  #   # p data
  # end
  
end


Cloudist.signal_trap!

Cloudist.start(:logging => true) {
  puts AMQP.settings.inspect
  
  unless ARGV.empty?
    puts "*** Please ensure you have a worker running ***"
    
    job_count = ARGV.pop.to_i
    $total_jobs = job_count
    job_count.times { |i| 
      log.info("Dispatching sandwich making job...")
      puts "Queued job: " + enqueue('make.sandwich', {:bread => 'white', :sandwich_number => i}).id
    }
  end
  
  add_listener(SandwichListener)  
}
