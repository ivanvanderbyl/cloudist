require "rubygems"

$:.unshift(File.expand_path("../../../lib", __FILE__))

require "cloudist"

Cloudist::Application.signal_trap!

AMQP.start(:heartbeat => 0, :logging => false) do
  q = Cloudist::Queue.new('encode.video')
  
  q.subscribe do |msg|
    p msg.body.to_hash
    
    msg = Cloudist::Message.new(msg.body)
    
    reply_q = Cloudist::ReplyQueue.new('encode.video')
    msg.publish(reply_q)
    
    # # p msg.headers.queue_name
    # msg.reply({:working => 1})
    # # msg.reply(:working => 2)
    # # msg.reply(:working => 3)
    # # msg.reply(:working => 4)
    # # msg.reply(:working => 5)
    # sleep(1)
    # msg.reply({:stopped => 6})
    # 
    # sleep(1)
    # msg.reply({:success => true})
  end
  
end