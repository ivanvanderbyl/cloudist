module Cloudist
  class SyncJobQueue < Cloudist::Queues::SyncQueue

    def initialize(queue_name, opts={})
      opts[:auto_delete] = false

      super(queue_name, opts)
    end
  end
end
