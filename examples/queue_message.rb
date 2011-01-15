$:.unshift File.dirname(__FILE__) + '/../lib'
require "rubygems"
require "cloudist"

ENV["AMQP_URL"] = 'amqp://test_pilot:t35t_p1l0t!@ec2-50-16-134-211.compute-1.amazonaws.com:5672/'

::Signal.trap('INT') { Cloudist.stop }
::Signal.trap('TERM'){ Cloudist.stop }

Cloudist.start {
  
  payload = Cloudist::Payload.new({:event => "started"})
  
  q = Cloudist::ReplyQueue.new('temp.reply.make.sandwich')
  q.setup
  q.publish_to_q(payload)
  
  stop
}