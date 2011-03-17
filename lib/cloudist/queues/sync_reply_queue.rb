module Cloudist
  class SyncReplyQueue < Cloudist::Queues::SyncQueue
    def initialize(queue_name, opts={})
      queue_name = Utils.reply_prefix(queue_name)
      opts[:auto_delete] = true
      opts[:nowait] = false
      super(queue_name, opts)
    end

    # def setup
    #   @q = bunny.queue(queue_name, opts)
    #   @ex = bunny.exchange('')
    #   q.bind(ex)
    # end

  end
end
