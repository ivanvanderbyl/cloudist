module Cloudist
  class Worker
    
    attr_reader :options
    
    def initialize(options)
      @options = options
    end
    
    def log
      Cloudist.log
    end
    
    def job(queue_name, &block)
      q = JobQueue.new(queue_name)
      q.subscribe do |request|
        j = Job.new(request.payload)
        j.instance_eval(&block)
        j.cleanup
      end
    end
    
  end
end
