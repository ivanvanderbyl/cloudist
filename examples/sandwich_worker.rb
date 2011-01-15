$:.unshift File.dirname(__FILE__) + '/../lib'
require "rubygems"
require "cloudist"

Cloudist.signal_trap!

Cloudist.start {
  log.info("Started Worker")
  
  worker {
    job('make.sandwich') {
      # Fire the started event
      started!
      
      log.info("JOB (#{id}) Make sandwich with #{data[:bread]} bread")
      log.debug(data.inspect)
      
      finished!
    }    
  }
}
