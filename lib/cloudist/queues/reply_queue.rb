module Cloudist
  class ReplyQueue < Cloudist::Queues::BasicQueue
    def initialize(queue_name, opts={})
      raise ArgumentError, "You must supply a queue_name" unless queue_name
      queue_name = Utils.reply_prefix(queue_name) unless queue_name.starts_with?(Utils.reply_prefix(''))
      opts[:auto_delete] = true
      opts[:nowait] = true
      super
    end

    # def setup(key = nil)
    #       @mq = AMQP::Channel.new
    #       @mq.prefetch(1)
    #       @q = @mq.queue(queue_name, opts)
    #       @ex = @mq.direct
    #       if key
    #         @q.bind(@ex, :key => key)
    #       else
    #         @q.bind(@ex)
    #       end
    #     end
    
    # def setup_exchange
    #   @ex = channel.direct
    #   q.bind(ex)
    # end

    # def subscribe(amqp_opts={}, opts={})
    #   super(amqp_opts, opts) do |request|
    #     yield request if block_given?
    #     self.destroy
    #   end
    # end
    # 
    # def teardown
    #   @q.delete
    #   super
    # end
    
  end
end
