require "bunny"
# require 'system_timer'

module Cloudist
  module Queues
    class SyncQueue
      attr_reader :queue_name, :opts
      attr_reader :q, :ex

      def initialize(queue_name, opts = {})
        opts = {
          :auto_delete => true,
          :durable => false,
          :prefetch => 1
        }.update(opts)

        @queue_name, @opts = queue_name, opts
      end
      
      def setup
        reconnect_on_error do
          @q = bunny.queue(queue_name, opts)
          @ex = bunny.exchange(queue_name)
          q.bind(ex)
        end
        
      end
      
      def subscribe
        raise NotImplementedError
      end
      
      # def call
      #   @q = nil
      #   
      #   begin
      #     reconnect_on_error do
      #       publish_to_ex(queue_name, data, opts, popts)
      #     end
      #   ensure
      #     if q
      #       @q.delete rescue nil
      #     end
      #   end
      # end
      
      def subscribe
        setup
        
        begin
          loop do
            response = q.pop
            encoded_message = response[:payload] if response.is_a?(Hash)
            queue_header = response[:properties] if response.is_a?(Hash)
            
            # return JSON.parse(result) unless result == :queue_empty
            unless encoded_message == :queue_empty
              request = Cloudist::Request.new(self, encoded_message, queue_header)
              begin
                raise Cloudist::ExpiredMessage if request.expired?
                yield request if block_given?

              rescue Cloudist::ExpiredMessage
                log.error "AMQP Message Timeout: #{tag} ttl=#{request.ttl} age=#{request.age}"
                request.ack if amqp_opts[:ack]

              rescue Object => e
                request.ack if amqp_opts[:ack]
                Cloudist.handle_error(e)
              end
            end
            sleep 0.1
          end
        end
      end
      
      def publish(payload)
        payload.set_reply_to(queue_name)
        body, headers = payload.formatted
        ex.publish(body, headers)
        destroy
        payload.publish
        return payload
      end

      def publish_to_q(payload)
        body, headers = payload.formatted
        q.publish(body, headers)
        payload.publish
        destroy
        return payload
      end
      
      def bunny
        @bunny ||= begin
          b = Bunny.new(Cloudist.settings)
          b.start
          b
        end
      end
      
      def reset_bunny
        @bunny = nil
      end
      
      def reconnect_on_error
        SystemTimer::timeout(20) do
          begin
            yield if block_given?
          rescue Bunny::ProtocolError
            sleep 0.5
            retry
          rescue Bunny::ConnectionError
            sleep 0.5
            reset_bunny
            retry
          rescue Bunny::ServerDownError
            sleep 0.5
            reset_bunny
            retry
          end
        end
      end
      
      def teardown
        # @q.unsubscribe
        # @mq.close
        bunny.stop
        # log.debug "AMQP Unsubscribed: #{tag}"
      end

      def destroy
        teardown
      end
    end
  end
end
