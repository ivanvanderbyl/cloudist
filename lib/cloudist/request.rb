module Cloudist
  class Request
    attr_reader :queue_header, :qobj, :payload, :start, :headers

    def initialize(queue, json_encoded_message, queue_header)
      @qobj, @queue_header = queue, queue_header

      @payload = Cloudist::Payload.new(json_encoded_message.dup, queue_header.headers.dup)
      @headers = @payload.parse_custom_headers

      @start = Time.now.utc.to_i
    end

    def q
      qobj.q
    end

    def ex
      qobj.ex
    end

    def mq
      qobj.mq
    end

    def age
      return -1 unless headers[:published_on]
      start - headers[:published_on]
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
    end

  end
end
