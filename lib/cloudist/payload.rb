module Cloudist
  DEFAULT_TTL = 300

  class Payload
    include Utils
    
    attr_accessor :hash, :headers

    def initialize(data_hash_or_json, headers = {})
      data_hash_or_json = parse_message(data_hash_or_json) if data_hash_or_json.is_a?(String)
      
      raise Cloudist::BadPayload, "Expected Hash for payload" unless data_hash_or_json.is_a?(Hash)

      @hash, @headers = HashWithIndifferentAccess.new(data_hash_or_json), headers
      update_headers
    end

    def formatted
      hash, headers = apply_custom_headers

      # Return message formatted as JSON and headers ready for transport
      [hash.to_json, headers]
    end
    
    def id
      @id ||= event_hash.to_s
    end
    
    def id=(new_id)
      @id = new_id.to_s
      update_headers
    end
    
    def frozen?
      headers.frozen?
    end
    
    def freeze!
      # headers.freeze
      # hash.freeze
    end
    
    def update_headers
      raise StaleHeadersError, "Headers cannot be changed because payload has already been published" if published?
      
      headers[:published_on] ||= hash.delete('published_on') || Time.now.utc.to_i
      headers[:ttl] ||= hash.delete('ttl') || Cloudist::DEFAULT_TTL

      # this is the event hash that gets transferred through various publish/reply actions
      headers[:event_hash] ||= event_hash

      # this value should be unique for each published/received message pair
      headers[:message_id] ||= create_event_hash
      
      # We use JSON for message transport exclusively
      headers[:content_type] ||= 'application/json'

      # some strange behavior with integers makes it better to
      # convert all amqp headers to strings to avoid any problems
      headers.each { |k,v| headers[k] = v.to_s }

      [hash, headers]
    end
    
    def parse_custom_headers
      return { } unless headers

      h = headers.dup

      h[:published_on] = h[:published_on].to_i

      h[:ttl] = h[:ttl].to_i rescue -1
      h[:ttl] = -1 if h[:ttl] == 0

      h
    end
    
    def set_reply_to(queue_name)
      headers[:reply_to] = "#{reply_prefix}.#{queue_name}.#{id}"
    end
    
    def event_hash
      @event_hash ||= headers[:event_hash] || hash.delete('event_hash') || create_event_hash
    end
    
    def create_event_hash
      s = Time.now.to_s + object_id.to_s + rand(100).to_s
      Digest::MD5.hexdigest(s)
    end
    
    def parse_message(raw)
      return { } unless raw
      JSON.parse(raw)
    end
    
    def [](key)
      hash[key]
    end
    
  end
end