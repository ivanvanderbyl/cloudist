module Cloudist
  class UnknownReplyTo < RuntimeError; end
  class ExpiredMessage < RuntimeError; end
  
  class BasicQueue
    attr_reader :queue_name, :opts
    attr_reader :q, :ex, :mq
    
    def initialize(queue_name, opts = {})
      opts = {
        :auto_delete => true,
        :durable => false,
        :prefetch => 1
      }.update(opts)
      
      @queue_name, @opts = queue_name, opts
    end
    
    def setup
      return if @setup == true
      
      @mq = MQ.new
      @q = @mq.queue(queue_name, opts)
      # if we don't specify an exchange name it defaults to the queue_name
      @ex = @mq.direct(opts[:exchange_name] || queue_name)

      q.bind(ex) if ex
      
      @setup = true
    end
    
    def log
      Cloudist.log
    end
    
    def tag
      s = "queue=#{q.name}"
      s += " exchange=#{ex.name}" if ex
      s
    end
    
    def subscribe(amqp_opts={}, opts={})
      setup
      
      q.subscribe(amqp_opts) do |queue_header, json_encoded_message|
        return if Cloudist.closing?
        
        request = Cloudist::Request.new(self, ::Marshal.load(json_encoded_message), queue_header)
        
        begin
          raise Cloudist::ExpiredMessage if request.expired?
          yield request if block_given?
          finished = Time.now.utc.to_i

        rescue Cloudist::ExpiredMessage
          log.info "amqp_message action=timeout #{tag} ttl=#{request.ttl} age=#{request.age} #{request.inspect}"
          request.ack if amqp_opts[:ack]

        rescue => e
          request.ack if amqp_opts[:ack]
          Cloudist.handle_error(e)
        end
      end
      log.info "amqp_subscribe #{tag}"
      self
    end
    
    def publish(payload)
      payload.set_reply_to(queue_name)
      body, headers = payload.formatted
      ex.publish(::Marshal.dump(body), headers)
      payload.publish
    end
    
    def publish_to_q(payload)
      body, headers = payload.formatted
      q.publish(body, headers)
      payload.publish
    end
    
    def teardown
      @q.unsubscribe
      @mq.close
      log.debug "amqp_unsubscribe #{tag}"
    end

    def destroy
      teardown
    end
  end
end