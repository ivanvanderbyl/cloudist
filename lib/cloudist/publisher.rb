module Cloudist
  class Publisher
    
    class << self
      def enqueue(queue_name, data)
        payload = Cloudist::Payload.new(data)
        
        queue = Cloudist::JobQueue.new(queue_name)
        
        queue.setup
        queue.publish(payload)
        
        return Job.new(payload)
      end
    end
    
  end
end
