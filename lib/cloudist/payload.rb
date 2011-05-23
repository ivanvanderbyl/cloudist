module Cloudist
  class Payload
    include Utils
    include Encoding
    
    attr_reader :body, :headers, :timestamp
    
    def initialize(body, headers = {})
      @published = false
      @timestamp = Time.now.to_f
      
      body = decode(body) if body.is_a?(String)
      @body = Hashie::Mash.new(decode(body))
      @headers = Hashie::Mash.new(headers)
      
      # puts "Initialised Payload: #{id}"
      
      parse_headers!
    end
    
    def find_or_create_id
      if headers["message_id"].present?
        headers.message_id
      else
        UUID.generate
      end
    end
    
    def id
      find_or_create_id
    end
    
    def to_a
      [encode(body), {:headers => encoded_headers}]
    end
    
    def parse_headers!
      headers[:published_on] ||= body.delete("timestamp") || timestamp
      headers[:ttl] ||= Cloudist::DEFAULT_TTL
      headers[:message_id] = id
      
      headers[:published_on] = headers[:published_on].to_f
      
      headers[:ttl] = headers[:ttl].to_i rescue -1
      headers[:ttl] = -1 if headers[:ttl] == 0
      
      # If this payload was received with a timestamp,
      # we don't want to override it on #timestamp
      if timestamp > headers[:published_on]
        @timestamp = headers[:published_on]
      end
      
      headers
    end
    
    def encoded_headers
      h = headers.dup
      h.each { |k,v| h[k] = v.to_s }
      return h
    end
    
    def set_reply_to(queue_name)
      headers[:reply_to] = reply_prefix(queue_name)
    end
    
    def reply_to
      headers.reply_to
    end
    
    def message_type
      headers.message_type
    end
    
    def [](key)
      self.body[key.to_s]
    end
    
    def method_missing(meth, *args, &blk)
      if body.has_key?(meth.to_s)
        return body[meth]
      elsif key = meth.to_s.match(/(.+)(?:\?$)/).to_a.last
        body.has_key?(key.to_s)
      else
        super
      end
    end
    
  end
end