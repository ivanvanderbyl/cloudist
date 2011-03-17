module Cloudist
  class ErrorCallback < Callback
    def call(payload)
      @payload = payload
      
      case source.arity
      when 1
        instance_exec(SafeError.new(payload), &source)
      else
        instance_exec(&source)
      end
    end
  end
  
  class SafeError
    def initialize(payload)
      @payload = payload
    end
    
    def message
      @payload.message
    end
    
    def class_name
      @payload.exception
    end
    
    alias :exception :class_name
    
    def name
      class_name
    end
    
    def to_s
      message
    end
    
    def backtrace
      @payload.backtrace
    end
  end
end
