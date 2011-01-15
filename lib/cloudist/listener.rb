module Cloudist
  class Listener
    
    attr_reader :job_queue_name
    
    def initialize(job_queue_name)
      @job_queue_name = job_queue_name
    end
    
    def subscribe(&block)
      reply_queue = Cloudist::ReplyQueue.new(job_queue_name)
      reply_queue.subscribe do |request|
        Cloudist.log.info("REPLY: #{request.payload.inspect}")
      end
    end
    
  end
end
