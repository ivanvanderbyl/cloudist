module Cloudist
  class Listener
    include Cloudist::CallbackMethods
    
    attr_reader :job_queue_name, :job_id, :callbacks
    
    class << self
      def listen_to(*job_queue_names)
        
      end
    end
  end
  
  class GenericListener < Listener
    
  end
end