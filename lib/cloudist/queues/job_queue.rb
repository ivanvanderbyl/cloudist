module Cloudist
  class JobQueue < Cloudist::Queues::BasicQueue
    attr_reader :prefetch

    def initialize(queue_name, opts={})
      @prefetch = opts.delete(:prefetch) || 1
      opts[:auto_delete] = false
      
      super(queue_name, opts)
    end

    # def setup
    #   # super
    #   # @mq.prefetch(self.prefetch)
    # end

    # def subscribe(amqp_opts={}, opts={})
    #   amqp_opts[:ack] = true
    #   super(amqp_opts, opts) do |request|
    #     EM.defer {
    #       begin
    #         yield request if block_given?
    #       ensure
    #         request.ack unless amqp_opts[:auto_ack] == false || Cloudist.closing?
    #       end
    #     }
    #   end
    # end
  end
end
