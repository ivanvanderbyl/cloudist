module Cloudist
  class Listener
    
    attr_reader :job_queue_name, :job_id
    
    def initialize(job_or_queue_name)
      if job_or_queue_name.is_a?(Cloudist::Job)
        @job_queue_name = Utils.reply_prefix(job_or_queue_name.payload.headers[:master_queue])
        @job_id = job_or_queue_name.id
      elsif job_or_queue_name.is_a?(String)
        @job_queue_name = Utils.reply_prefix(job_or_queue_name)
        @job_id = nil
      else
        raise ArgumentError, "Invalid listener type, accepts job queue name or Cloudist::Job instance"
      end
    end
    
    def subscribe(&block)
      reply_queue = Cloudist::ReplyQueue.new(job_queue_name)
      reply_queue.setup(job_id) if job_id
      
      reply_queue.subscribe do |request|        
        # job = Job.new(request.payload)
        request.instance_eval(&block)
      end
    end
    
  end
end
