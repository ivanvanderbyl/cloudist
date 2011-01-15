$:.unshift File.dirname(__FILE__) + '/../lib'
require "rubygems"
require "cloudist"

Cloudist.signal_trap!

Cloudist.start {
  
  log.info("Dispatching sandwich making job...")
  enqueue('make.sandwich', {:bread => 'white'})
  
  # Listen to all sandwich jobs
  listen('make.sandwich') {
    Cloudist.log.info("Make sandwich event: #{id}")
  }
  
}
