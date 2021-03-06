module Cloudist
  class JobQueue < Cloudist::Queues::BasicQueue

    def initialize(queue_name, options={})
      options[:auto_delete] = false
      options[:nowait] = false

      @prefetch = Cloudist.worker_prefetch
      puts "Prefetch: #{@prefetch}"
      super(queue_name, options)
    end

    # def initialize(queue_name, options={})
    #   @prefetch = 1
    #   # opts[:auto_delete] = false
    #
    #   super(queue_name, options)
    # end

    # def setup_exchange
    #   @exchange = channel.direct(queue_name)
    #   queue.bind(exchange)
    # end

  end
end
