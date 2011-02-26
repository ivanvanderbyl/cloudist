module Cloudist
  module CallbackMethods
    def data
      payload.body
    end
    
    def headers
      payload.headers
    end
    
    def job_id
      headers[:message_id]
    end
    
  end
end