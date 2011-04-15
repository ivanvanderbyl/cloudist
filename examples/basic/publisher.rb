require "rubygems"

$:.unshift(File.expand_path("../../../lib", __FILE__))

require "cloudist"

q_name = 'make.sandwich'

AMQP.start(:heartbeat => 10, :logging => false) do
  payload = Cloudist::Payload.new({:event => "started"})
  
  reply_q = Cloudist::ReplyQueue.new(q_name)
  reply_q.subscribe do |request|
    p request.payload.body
    
  end
  
  
  q = Cloudist::JobQueue.new(q_name)
  p q.publish(payload)
  
  # Cloudist.stop
end