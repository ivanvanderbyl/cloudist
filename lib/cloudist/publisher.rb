module Cloudist
  class Publisher
    
    class << self
      def enqueue(queue_name, data)
        payload = Cloudist::Payload.new(data)
        
        queue = Cloudist::JobQueue.new(queue_name)
        
        queue.setup
        
        # send_message = proc {
          queue.publish(payload)
        # }
        # EM.next_tick(&send_message)
        
        return Job.new(payload)
      end
    end
    
  end
end
