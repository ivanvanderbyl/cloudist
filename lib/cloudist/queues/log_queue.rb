module Cloudist
  class LogQueue < Cloudist::ReplyQueue
    def initialize(queue_name, opts={})
      queue_name = Utils.log_prefix(queue_name)
      super(queue_name, opts)
    end
    
  end
end
