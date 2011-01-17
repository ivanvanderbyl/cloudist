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
      # headers = {
      #   :message_id => payload.headers[:message_id],
      #   :message_type => "reply"
      # }.update(headers)
      
      reply_payload = Payload.new(data, headers)
      
      reply_queue = ReplyQueue.new(payload.reply_to)
      reply_queue.setup
      published_headers = reply_queue.publish_to_q(reply_payload)
      
      log.debug("Replying: #{data.inspect} - Headers: #{published_headers.inspect}")
    end
    
    # Sends a progress update
    # Inputs: percentage - Integer
    # Optional description, this could be displayed to the user e.g. Resizing image
    def progress(percentage, description = nil)
      
    end
    
    def event(event_name, event_data = {}, options = {})
      # options = {
      #   :echo => false
      # }.update(options)
      # 
      # event_data = {} if event_data.nil?
      # event_data.merge!(payload.body) if options[:echo] == true
      # 
      # reply(event_data.update(:message_type => "event", :event => event_name))
      reply({:event => event_name}, {:event => event_name, :message_type => 'event'})
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
