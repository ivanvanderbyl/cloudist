module Cloudist
  class ErrorCallback < Callback  
    def call(payload)
      @payload = payload
      
      case source.arity
      when 0
        instance_exec(&source)
      when 1
        instance_exec(payload.exception, &source)
      end
    end
  end
end
