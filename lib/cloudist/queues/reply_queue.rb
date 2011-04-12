module Cloudist
  class ReplyQueue < Cloudist::Queues::BasicQueue
    def initialize(queue_name, opts={})
      opts[:auto_delete] = true
      opts[:nowait] = true
      super
    end

    def setup(key = nil)
      @mq = AMQP::Channel.new
      @mq.prefetch(1)
      @q = @mq.queue(queue_name, opts)
      @ex = @mq.direct
      if key
        @q.bind(@ex, :key => key)
      else
        @q.bind(@ex)
      end
    end

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
