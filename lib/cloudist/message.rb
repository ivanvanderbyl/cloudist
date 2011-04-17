module Cloudist
  class Message
    include Cloudist::Encoding
    
    attr_reader :body, :headers, :id, :timestamp
    
    # Expects body to be decoded
    def initialize(body, headers = {})
      @body = Hashie::Mash.new(body.dup)
      
      @id ||= headers[:message_id] || headers[:id] && headers.delete(:id) || UUID.generate
      @headers = Hashie::Mash.new(headers.dup)
      
      @timestamp = Time.now.utc.to_f
      
      update_headers(headers)
    end
    
    alias_method :data, :body
    
    def update_headers(new_headers = {})
      update_headers!
      headers.merge!(new_headers)
    end
    
    def update_headers!
      headers[:ttl] ||= Cloudist::DEFAULT_TTL
      headers[:timestamp] = timestamp
      headers[:message_id] ||= id
      headers[:message_type] = 'message'
      headers[:queue_name] ||= 'test'
      
      headers.each { |k,v| headers[k] = v.to_s }
    end
    
    # Convenience method for replying
    # Constructs a reply message and publishes it
    def reply(body, reply_headers = {})
      raise RuntimeError, "Cannot reply to an unpublished message" unless published?
      
      msg = Message.new(body, reply_headers)
      msg.set_reply_header
      reply_q = Cloudist::ReplyQueue.new(headers[:queue_name])
      msg.publish(reply_q)
    end
    
    # Publishes this message to the exchange or queue
    # Queue should be a Cloudist::Queue object responding to #publish
    def publish(queue)
      raise ArgumentError, "Publish expects a Cloudist::Queue instance" unless queue.is_a?(Cloudist::Queue)
      set_queue_name_header(queue)
      update_published_date!
      update_headers!
      queue.publish(self)
    end
    
    def update_published_date!
      headers[:published_on] = Time.now.utc.to_f
    end
    
    # This is so we can reply back to the sender
    def set_queue_name_header(queue)
      update_headers(:queue_name => queue.name)
    end
    
    def published?
      @published ||= !!@headers.published_on
    end
    
    def created_at
      headers.timestamp ? Time.at(headers.timestamp.to_f) : timestamp
    end
    
    def published_at
      headers[:published_on] ? Time.at(headers[:published_on].to_f) : timestamp
    end
    
    def latency
      (published_at.to_f - created_at.to_f)
    end
    
    def encoded
      [encode(body), {:headers => headers}]
    end
    
    def inspect
      "<#{self.class.name} id=#{id}>"
    end
    
    private
    
    def set_reply_header
      headers[:message_type] = 'reply'
    end
    
  end
end
