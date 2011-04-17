require "rubygems"

$:.unshift(File.expand_path("../../../lib", __FILE__))

require "cloudist"

q_name = 'encode.video'
total = 10
count = 0

AMQP.start(:heartbeat => 0, :logging => false) do
  q = Cloudist::Queue.new(q_name)
  
  pub = proc {
    msg = Cloudist::Message.new({:event => "started"})
    msg.publish(q)
  }
  
  # reply_q = Cloudist::ReplyQueue.new(q_name)
  # reply_q.subscribe do |msg|
  #   p msg.body.to_hash
  #   
  #   # if msg.body.success == true
  #   #   p total - count
  #   #   count += 1
  #   #   pub.call if count < total
  #   #   Cloudist.stop if count == total
  #   # end
  # end
  
  pub.call
  Cloudist.stop
end
