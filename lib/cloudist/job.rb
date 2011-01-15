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
      
    end
    
    def reply(data, headers = {})
      # opts.merge!(default_publish_opts)
      # reply_to = droid_headers[:reply_to] || self.msg['reply_to']
      # raise UnknownReplyTo unless reply_to
      # JobQueue.publish_to_q(reply_to, data, opts, popts)
      
      # Factory.log.debug("Reply queue: #{request.reply_to}")
      # 
      # reply_queue = ReplyQueue.new(request.reply_to)
      # reply_queue.setup
      # 
      # response, headers = Factory::Utils.format_publish(data, headers)
      # reply_queue.q.publish(response, headers)
      log.debug("Replying: #{data.inspect} - Headers: #{headers.inspect}")
      
      
      
    end
    
    def event(event_name, data = {})
      data = {} unless data
      reply({:event => event_name})
    end
    
    def method_missing(meth, *args, &blk)
      if meth.to_s.ends_with?("!")
        event(meth.to_s.gsub(/(!)$/, ''), args.shift)
      else
        super
      end
    end
    
  end
end
