$:.unshift File.dirname(__FILE__) + '/../lib'
require "rubygems"
require "cloudist"

ENV["AMQP_URL"] = 'amqp://test_pilot:t35t_p1l0t!@ec2-50-16-134-211.compute-1.amazonaws.com:5672/'

::Signal.trap('INT') { Cloudist.stop }
::Signal.trap('TERM'){ Cloudist.stop }

Cloudist.start {
  log.info("Dispatching sandwich making job...")
  
  job = enqueue('make.sandwich', {:bread => 'brown'})
  log.debug(job.inspect)
  
  listen(job) {
    
  }
  
  
}
