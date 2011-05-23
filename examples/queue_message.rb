$:.unshift File.dirname(__FILE__) + '/../lib'
require "rubygems"
require "cloudist"

Cloudist.signal_trap!
# 
# This demonstrates how to send a message to a listener
# 
Cloudist.start {
  
  payload = Cloudist::Payload.new(:event => :started, :message_type => 'event')
  
  q = Cloudist::ReplyQueue.new('temp.reply.make.sandwich')
  q.publish(payload)
  
  stop
}
