module Cloudist
  class Listener
    
    attr_accessor :job_id
    
    def initialize(job_or_id)
      if job_or_id.is_a?(Cloudist::Job)
        job_or_id = job_or_id.id
      end
      
      @job_id = job_or_id
    end
    
    def subscribe!
      Cloudist::ReplyQueue.new()
    end
    
  end
end