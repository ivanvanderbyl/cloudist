module Cloudist
  class Request
    include Cloudist::Encoding
    
    attr_reader :queue_header, :qobj, :payload, :start, :headers, :body

    def initialize(queue, encoded_body, queue_header)
      @qobj, @queue_header = queue, queue_header

      @body = decode(encoded_body)
      @headers = parse_custom_headers(queue_header)
      
      @payload = Cloudist::Payload.new(encoded_body, queue_header.headers.dup)
      @headers = @payload.parse_custom_headers

      @start = Time.now.utc.to_f
    end
    
    def parse_custom_headers(amqp_headers)
      h = amqp_headers.headers.dup

      h[:published_on] = h[:published_on].to_i

      h[:ttl] = h[:ttl].to_i rescue -1
      h[:ttl] = -1 if h[:ttl] == 0

      h
    end
    
    def for_message
      [body.dup, queue_header.headers.dup]
    end

    def q
      qobj.queue
    end

    def ex
      qobj.exchange
    end

    def mq
      qobj.channel
    end
    
    def channel
      mq
    end

    def age
      return -1 unless headers[:published_on]
      start - headers[:published_on].to_f
    end

    def ttl
      headers[:ttl] || -1
    end

    def expired?
      return false if ttl == -1
      age > ttl
    end

    def acked?
      @acked == true
    end

    def ack
      return if acked?
      queue_header.ack
      @acked = true
    rescue AMQP::ChannelClosedError => e
      Cloudist.handle_error(e)
    end

  end
end
