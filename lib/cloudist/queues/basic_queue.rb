module Cloudist
  class UnknownReplyTo < RuntimeError; end
  class ExpiredMessage < RuntimeError; end
  
  module Queues
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
        print_status
        q.subscribe(amqp_opts) do |queue_header, json_encoded_message|
          next if Cloudist.closing?

          request = Cloudist::Request.new(self, json_encoded_message, queue_header)

          begin
            raise Cloudist::ExpiredMessage if request.expired?
            yield request if block_given?
            # finished = Time.now.utc.to_i
            # log.debug("Finished Job in #{finished - request.start} seconds")

          rescue Cloudist::ExpiredMessage
            log.error "AMQP Message Timeout: #{tag} ttl=#{request.ttl} age=#{request.age}"
            request.ack if amqp_opts[:ack]

          rescue => e
            request.ack if amqp_opts[:ack]
            Cloudist.handle_error(e)
          end
        end
        log.info "AMQP Subscribed: #{tag}"
        self
      end

      def print_status
        q.status{ |num_messages, num_consumers|
          log.info("STATUS: #{q.name}: JOBS: #{num_messages} WORKERS: #{num_consumers+1}")
        }
      end

      def publish(payload)
        payload.set_reply_to(queue_name)
        body, headers = payload.formatted
        ex.publish(body, headers)
        payload.publish
      end

      def publish_to_q(payload)
        body, headers = payload.formatted
        q.publish(body, headers)
        payload.publish
        return headers
      end

      def teardown
        @q.unsubscribe
        @mq.close
        log.debug "AMQP Unsubscribed: #{tag}"
      end

      def destroy
        teardown
      end
    end
  end
end