module Cloudist
  class Worker
    
    attr_reader :job, :queue
    
    def initialize(job, queue)
      @job, @queue = job, queue
    end
    
    def data
      job.data
    end
    
    def headers
      job.headers
    end
    
    def process
      raise NotImplementedError, "Your worker class must subclass this method"
    end
    
    def log
      Cloudist.log
    end
    
  end
end
