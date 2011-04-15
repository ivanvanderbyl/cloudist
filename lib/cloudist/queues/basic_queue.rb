module Cloudist
  class UnknownReplyTo < RuntimeError; end
  class ExpiredMessage < RuntimeError; end
  
  module Queues
    class BasicQueue
      attr_reader :queue_name, :opts
      attr_reader :q, :ex, :channel

      def initialize(queue_name, opts = {})
        opts = {
          :auto_delete => true,
          :durable => false
        }.update(opts)

        @queue_name, @opts = queue_name, opts
        
        setup
      end
      
      def inspect
        "<#{self.class.name} queue_name=#{queue_name}>"
      end

      def setup
        return if @is_setup == true
        @is_setup = true
        
        puts "Setup"
        log.debug(opts.inspect)
        
        @channel = ::AMQP::Channel.new
        
        # Set up QOS. If you do not do this then the subscribe in receive_message
        # will get overwelmd and the whole thing will collapse in on itself.
        @channel.prefetch(1)
        
        @q = @channel.queue(queue_name, opts)
        
        setup_exchange
        
        log.info tag
      end
      
      def setup_exchange
        @ex = channel.direct(queue_name)
        q.bind(ex)
      end

      def log
        Cloudist.log
      end

      def tag
        [].tap do |a|
          a << "queue=#{q.name}" if q
          a << "exchange=#{ex.name}" if ex
        end.join(' ')
      end
      
      def subscribe(amqp_opts={}, opts={})
        q.subscribe(:ack => true) do |queue_header, encoded_message|
          next if Cloudist.closing?
          request = Cloudist::Request.new(self, encoded_message, queue_header)
          
          EM.defer do
            begin
              raise Cloudist::ExpiredMessage if request.expired?
              yield request if block_given?

            rescue Cloudist::ExpiredMessage
              log.error "AMQP Message Timeout: #{tag} ttl=#{request.ttl} age=#{request.age}"
              # request.ack

            rescue => e
              # request.ack
              Cloudist.handle_error(e)
            ensure
              request.ack
              # unless Cloudist.closing?
              # finished = Time.now.utc.to_i
              # log.debug("Finished Job in #{finished - request.start} seconds")
            end
          end
        end
        self
      end

      def print_status
        # q.status{ |num_messages, num_consumers|
        #   log.info("STATUS: #{q.name}: JOBS: #{num_messages} WORKERS: #{num_consumers+1}")
        # }
      end

      def publish(payload)
        payload.set_reply_to(queue_name)
        body, headers = payload.formatted
        ex.publish(body, headers)
        payload.publish
      end

      def publish_to_q(payload)
        body, headers = payload.formatted
        EM.defer {
          q.publish(body, headers)
        }
        payload.publish
        return headers
      end

      def teardown
        @q.unsubscribe
        @channel.close
        log.debug "AMQP Unsubscribed: #{tag}"
      end

      def destroy
        teardown
      end
    end
  end
end