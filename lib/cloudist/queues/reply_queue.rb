module Cloudist
  class ReplyQueue < Cloudist::Queue
    def initialize(name, options = {})
      name = Utils.reply_prefix(name) unless name.starts_with?(Utils.reply_prefix(''))
      options[:auto_delete] = true
      options[:nowait] = true
      super(name, options)
    end
    
    def publish(msg)
      raise ArgumentError, "Publish expects a Cloudist::Message object" unless msg.is_a?(Cloudist::Message)
      
      body, headers = msg.encoded
      publish_to_q(body, headers)
      p msg.body.to_hash
    end
    
    def setup_exchange
      @ex = channel.direct
      setup_binding
    end
  end
end
