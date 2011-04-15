require "rubygems"

$:.unshift(File.expand_path("../../../lib", __FILE__))

require "cloudist"

Cloudist.signal_trap!

AMQP.start(:heartbeat => 10, :logging => false) do  
  q = Cloudist::JobQueue.new('make.sandwich')
  
  q.subscribe do |request|
    p request.payload.body
    
    job = Cloudist::Job.new(request.payload)
    
    # Echo back payload body
    job.reply(request.payload.body)
  end
  
end