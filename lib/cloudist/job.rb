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
    
    def reply(body, headers = {}, options = {})
      options = {
        :echo => false
      }.update(options)
      
      headers = {
        :message_id => payload.headers[:message_id],
        :message_type => "reply"
      }.update(headers)
      
      # Echo the payload back
      # body.merge!(payload.body) if options[:echo] == true
      
      reply_payload = Payload.new(body, headers)
      
      reply_queue = ReplyQueue.new(payload.reply_to)
      published_headers = reply_queue.publish(reply_payload)
      
      # log.debug("Replying: #{body.inspect} HEADERS: #{headers.inspect}")
      reply_payload
    end
    
    # Sends a progress update
    # Inputs: percentage - Integer
    # Optional description, this could be displayed to the user e.g. Resizing image
    def progress(percentage, description = nil)
      reply({:progress => percentage, :description => description}, {:message_type => 'progress'})
    end
    
    def event(event_name, event_data = {}, options = {})
      event_data ||= {}
      reply(event_data, {:event => event_name, :message_type => 'event'}, options)
    end
    
    def safely(&blk)
      yield
    rescue Exception => e
      handle_error(e)
    end
    
    def handle_error(e)
      reply({:exception => e.class.name.to_s, :message => e.message.to_s, :backtrace => e.backtrace}, {:message_type => 'error'})
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
