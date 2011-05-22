module Cloudist
  class UnknownReplyTo < RuntimeError; end
  class ExpiredMessage < RuntimeError; end
  
  module Queues
    class BasicQueue
      attr_reader :queue_name, :options
      attr_reader :queue, :exchange, :channel, :prefetch
      
      alias :q :queue
      alias :ex :exchange
      alias :mq :channel
      
      def initialize(queue_name, options = {})
        self.prefetch ||= options.delete(:prefetch) || 1
        
        options = {
          :auto_delete => true,
          :durable => false
        }.update(options)

        @queue_name, @options = queue_name, options
      end

      def setup
        return if @setup.eql?(true)
        
        @channel ||= AMQP::Channel.new(Cloudist.connection) do
          channel.prefetch(self.prefetch, false) if self.prefetch.present?
        end
        
        @queue = @channel.queue(queue_name, options)
        
        setup_exchange

        # queue.bind(exchange) if exchange

        @setup = true
      end
      
      def setup_exchange
        @exchange = channel.direct("")
      end

      # def setup_exchange
      #   @exchange = channel.direct(queue_name)
      #   queue.bind(exchange)
      # end

      def log
        Cloudist.log
      end

      def tag
        s = "queue=#{queue.name}"
        s += " exchange=#{exchange.name}" if exchange
        s
      end
      
      def subscribe(&block)
        setup
        
        queue.subscribe(:ack => true) do |queue_header, encoded_message|
          # next if Cloudist.closing?

          request = Cloudist::Request.new(self, encoded_message, queue_header)

          begin
            raise Cloudist::ExpiredMessage if request.expired?
            yield request if block_given?

          rescue Cloudist::ExpiredMessage
            log.error "AMQP Message Timeout: #{tag} ttl=#{request.ttl} age=#{request.age}"

          rescue => e
            Cloudist.handle_error(e)
          ensure
            request.ack
          end
        end
        log.info "AMQP Subscribed: #{tag}"
        self
      end

      def print_status
        # queue.status{ |num_messages, num_consumers|
        #   log.info("STATUS: #{queue.name}: JOBS: #{num_messages} WORKERS: #{num_consumers+1}")
        # }
      end

      def publish(payload)
        payload.set_reply_to(queue_name)
        body, headers = payload.formatted
        headers.merge!(:routing_key => queue.name)
        exchange.publish(body, headers)
        payload.publish
      end

      def publish_to_q(payload)
        body, headers = payload.formatted
        # headers.merge!(:routing_key => queue.name)
        queue.publish(body, headers)
        payload.publish
        return headers
      end

      def teardown
        @queue.unsubscribe
        @channel.close
        log.debug "AMQP Unsubscribed: #{tag}"
      end

      def destroy
        teardown
      end
    end
  end
end