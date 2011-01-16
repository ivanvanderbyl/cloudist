$:.unshift File.dirname(__FILE__) + '/../lib'
require "rubygems"
require "cloudist"

::Signal.trap('INT') { Cloudist.stop }
::Signal.trap('TERM'){ Cloudist.stop }

Cloudist.start {
  
  payload = Cloudist::Payload.new({:event => "started"})
  
  q = Cloudist::ReplyQueue.new('temp.reply.make.sandwich')
  q.setup
  q.publish_to_q(payload)
  
  stop
}