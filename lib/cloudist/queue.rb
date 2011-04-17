module Cloudist
  class Queue
    
    attr_reader :options, :name, :channel, :q, :ex
    
    class_attribute :cached_queues
    
    def initialize(name, options = {})
      self.class.cached_queues ||= {}
      
      options = {
        :auto_delete => false,
        :durable => true
      }.update(options)
      
      @name, @options = name, options
      
      setup
      p self.cached_queues.keys
      
      log.debug(tag)
      purge
    end
    
    def purge
      q.purge
    end
    
    def inspect
      "<#{self.class.name} name=#{name} exchange=#{ex ? ex.name : 'nil'}>"
    end
    
    def log
      Cloudist.log
    end

    def tag
      [].tap { |a|
        a << "queue=#{q.name}" if q
        a << "exchange=#{ex.name}" if ex
      }.join(' ')
    end
    
    def publish(msg)
      raise ArgumentError, "Publish expects a Cloudist::Message object" unless msg.is_a?(Cloudist::Message)
      
      body, headers = msg.encoded
      # EM.defer {
        publish_to_ex(body, headers)
      # }
      
      p msg.body.to_hash
    end
    
    # def channel
    #   self.class.channel
    # end
    # 
    # def q
    #   self.class.q
    # end
    # 
    # def ex
    #   self.class.ex
    # end
    
    def publish_to_ex(body, headers = {})
      ex.publish(body, headers)
    end
    
    def publish_to_q(body, headers = {})
      q.publish(body, headers)
    end
    
    def teardown
      q.unsubscribe
      channel.close
      log.debug "AMQP Unsubscribed: #{tag}"
    end

    def destroy
      teardown
    end
    
    def subscribe(options = {}, &block)
      options[:ack] = true
      q.subscribe(options) do |queue_header, encoded_message|
        request = Cloudist::Request.new(self, encoded_message, queue_header)
        
        msg = Cloudist::Message.new(*request.for_message)
        
        EM.defer do
          begin
            raise Cloudist::ExpiredMessage if request.expired?
            yield msg
            
          rescue Cloudist::ExpiredMessage
            log.error "AMQP Message Timeout: #{tag} ttl=#{request.ttl} age=#{request.age}"
            
          rescue Exception => e
            Cloudist.handle_error(e)
            
          ensure
            request.ack unless Cloudist.closing?
          end
        end
      end
    end
    
    private
    
    def setup
      if self.class.cached_queues.keys.include?(name.to_sym)
        @q = self.class.cached_queues[name.to_sym][:q]
        @ex = self.class.cached_queues[name.to_sym][:ex]
        @channel = self.class.cached_queues[name.to_sym][:channel]
        setup_binding
      else
        puts "Setup"

        setup_channel
        setup_queue
        setup_exchange

        self.class.cached_queues[name.to_sym] = {:q => q, :ex => ex, :channel => channel}
      end
      setup_binding
    end
    
    def setup_channel
      @channel = ::AMQP::Channel.new
      
      # Set up QOS. If you do not do this then the subscribe in receive_message
      # will get overwelmd and the whole thing will collapse in on itself.
      channel.prefetch(1)
    end
    
    def setup_queue
      @q = channel.queue(name, options)
    end
    
    def setup_exchange
      @ex = channel.direct(name)
      # setup_binding
    end
    
    def setup_binding
      q.bind(ex)
    end
    
  end
end
