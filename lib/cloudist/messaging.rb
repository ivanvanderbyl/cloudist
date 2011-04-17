module Cloudist
  autoload :Singleton, 'singleton'
  
  class Messaging
    include Singleton
    
    class << self
      
      def active_queues
        instance.active_queues
      end
      
      def add_queue(queue)
        (instance.active_queues ||= {}).merge!({queue.name.to_s => queue})
        instance.active_queues
      end
      
      def remove_queue(queue_name)
        (instance.active_queues ||= {}).delete(queue_name.to_s)
        instance.active_queues
      end
    end
    
    attr_accessor :active_queues
    
    
    
  end
end
