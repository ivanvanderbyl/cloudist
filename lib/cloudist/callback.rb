module Cloudist
  class Callback

    attr_reader :payload, :source

    def initialize(source)
      @source = source
    end
    
    def call(payload)
      @payload = payload
      instance_eval(&source)
    end
    
    def data
      payload.body
    end
    
    def headers
      payload.headers
    end
    
    def runtime
      
    end
    
  end
end
