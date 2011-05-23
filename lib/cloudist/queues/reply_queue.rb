module Cloudist
  class ReplyQueue < Cloudist::Queues::BasicQueue
    def initialize(queue_name, options={})
      options[:auto_delete] = true
      options[:nowait] = true
      
      @prefetch = 2
      
      super(queue_name, options)
    end
    
    # def subscribe(&block)
    #   super do |request|
    #     yield request if block_given?
    #     teardown
    #   end
    # end
    
    # def teardown
    #   queue.delete
    #   super
    # end
    
  end
end
