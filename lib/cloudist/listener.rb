module Cloudist
  class Listener
    include Cloudist::CallbackMethods
    
    attr_reader :job_queue_name, :job_id, :callbacks
    
    @@valid_callbacks = ["event", "progress", "reply", "update", "error"]
    
    def initialize(job_or_queue_name)
      @callbacks = {}
      
      if job_or_queue_name.is_a?(Cloudist::Job)
        @job_queue_name = Utils.reply_prefix(job_or_queue_name.payload.headers[:master_queue])
        @job_id = job_or_queue_name.id
      elsif job_or_queue_name.is_a?(String)
        @job_queue_name = Utils.reply_prefix(job_or_queue_name)
        @job_id = nil
      else
        raise ArgumentError, "Invalid listener type, accepts job queue name or Cloudist::Job instance"
      end
    end
    
    def subscribe(&block)
      reply_queue = Cloudist::ReplyQueue.new(job_queue_name)
      reply_queue.setup(job_id) if job_id
      
      self.instance_eval(&block)
      
      reply_queue.subscribe do |request|
        payload = request.payload
        
        key = [payload.message_type.to_s, payload.headers[:event]].compact.join(':')
        
        # If we want to get a callback on every event, do it here
        if callbacks.has_key?('everything')
          callbacks['everything'].each do |c|
            c.call(payload)
          end
        end
        
        if callbacks.has_key?('error')
          callbacks['error'].each do |c|
            # c.call(payload)
            
          end
        end
        
        if callbacks.has_key?(key)
          callbacks_to_call = callbacks[key]
          callbacks_to_call.each do |c|
            c.call(payload)
          end
        end
      end
    end
    
    def everything(&blk)
      (@callbacks['everything'] ||= []) << Callback.new(blk)
    end
    
    def method_missing(meth, *args, &blk)
      if @@valid_callbacks.include?(meth.to_s)
        
        # callback should in format of "event:started" or "progress"
        key = [meth.to_s, args.shift].compact.join(':')
        
        case meth.to_sym
        when :error
          (@callbacks[key] ||= []) << ErrorCallback.new(blk)
        else
          (@callbacks[key] ||= []) << Callback.new(blk)
        end
      else
        super
      end
    end
    
  end
end
