module Cloudist
  class ReplyQueue < Cloudist::Queues::BasicQueue
    def initialize(queue_name, options={})
      options[:auto_delete] = true
      options[:nowait] = true
      
      @prefetch = 2
      
      super(queue_name, options)
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
