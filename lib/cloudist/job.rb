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
      payload.body
    end
    
    def log
      Cloudist.log
    end
    
    def cleanup
      
    end
    
    def reply(data, headers = {})
      # headers.update(:message_id => payload.headers[:message_id])
      headers = {
        :message_id => payload.headers[:message_id],
        :reply_type => "reply"
      }.update(headers)
      
      reply_payload = Payload.new(data, headers)
      
      reply_queue = ReplyQueue.new(payload.reply_to)
      reply_queue.setup
      reply_queue.publish_to_q(reply_payload)
      
      # log.debug("Replying: #{data.inspect} - Payload: #{reply_payload.inspect}")
    end
    
    def event(event_name, data = {})
      data = {} unless data
      reply({:event => event_name}.merge(payload.body), {:reply_type => "event"})
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
