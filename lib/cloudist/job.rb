module Cloudist
  class Job
    attr_reader :payload
    def initialize(payload)
      @payload = payload
    end
    
    def id
      payload.id
    end
    
    def data
      payload.hash
    end
    
    def log
      Cloudist.log
    end
    
    def cleanup
      log.info("Cleanup")
    end
    
  end
end
