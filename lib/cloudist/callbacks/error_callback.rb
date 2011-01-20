module Cloudist
  class ErrorCallback < Callback  
    def call(payload)
      @payload = payload
      
      case source.arity
      when 1
        instance_exec(payload.exception, &source)
      else
        instance_exec(&source)
      end
    end
  end
end
