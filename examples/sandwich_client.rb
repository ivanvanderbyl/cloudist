$:.unshift File.dirname(__FILE__) + '/../lib'
require "rubygems"
require "cloudist"

ENV["AMQP_URL"] = 'amqp://guest:guest@localhost:5672/'

::Signal.trap('INT') { Cloudist.stop }
::Signal.trap('TERM'){ Cloudist.stop }

Cloudist.start {
  log.info("Dispatching sandwich making job...")
  
  job = enqueue('make.sandwich', {:bread => 'brown'})
  log.debug(job.inspect)
  
  listen(job) {
    
  }
  
  
}
