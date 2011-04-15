module Cloudist
  class Message
    attr_reader :body, :headers, :id, :queue, :timestamp
    
    # Expects body to be decoded
    # Queue should be a Cloudist::Queue object responding to #publish
    def initialize(body, headers = {})
      @queue = queue
      
      @id ||= headers[:message_id] || headers[:id] && headers.delete(:id) || UUID.generate
      
      @body = Hashie::Mash.new(body.dup)
      @headers = Hashie::Mash.new(headers.dup)
      @timestamp = Time.now.to_f
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
    end
    
    # Convenience method for replying
    # Constructs a reply message and publishes it
    def reply(body, headers = {})
      # publish response
    end
    
    # Publishes this message to the exchange or queue
    def publish(queue)
      update_published_date!
      update_headers!
      queue.publish(self)
    end
    
    def update_published_date!
      headers[:published_on] = Time.now.to_f
    end
    
    def published?
      @published ||= !!@headers.timestamp
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
    
  end
end
