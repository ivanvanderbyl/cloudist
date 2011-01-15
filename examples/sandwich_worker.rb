$:.unshift File.dirname(__FILE__) + '/../lib'
require "rubygems"
require "cloudist"

ENV["AMQP_URL"] = 'amqp://guest:guest@localhost:5672/'

::Signal.trap('INT') { Cloudist.stop }
::Signal.trap('TERM'){ Cloudist.stop }

Cloudist.start {
  log.info("Started Worker")
  
  worker {
    job('make.sandwich') {
      log.info("Make sandwich - " + data.inspect)
    }
  }
}
