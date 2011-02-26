require "active_support"
module Cloudist
  class Listener
    include Cloudist::CallbackMethods
    include ActiveSupport::Callbacks
    
    attr_reader :job_queue_name, :payload
    
    class_attribute :job_queue_names
    class_attribute :reply_queues
    
    class << self
      def listen_to(*job_queue_names)
        self.job_queue_names = job_queue_names.map { |q| Utils.reply_prefix(q) }
      end
      
      def subscribe(queue_name)
        raise RuntimeError, "You can't subscribe until EM is running" unless EM.reactor_running?
        
        self.reply_queues ||= []
        
        reply_queue = Cloudist::ReplyQueue.new(queue_name)
        
        reply_queue.subscribe do |request|
          new(request)
        end
        
        self.reply_queues << reply_queue
      end
      
      def before(*args, &block)
        set_callback(:call, :before, *args, &block)
      end

      def after(*args, &block)
        set_callback(:call, :after, *args, &block)
      end
    end
    
    define_callbacks :call, :rescuable => true
    
    # We will be initialized everytime a new reply comes through
    def initialize(request)
      # @job_queue_name
      # @job_id
      @payload = request.payload
      
      key = [payload.message_type.to_s, payload.headers[:event]].compact.join(':')
      
      meth, *args = handle_key(key)
      
      if self.respond_to?(meth)
        if method(meth).arity <= args.size
          call(meth, args.first(method(meth).arity))
        else
          raise ArgumentError, "Unable to fire callback (#{meth}) because we don't have enough args"
        end
      end
    end
    
    def handle_key(key)
      key = key.split(':', 2)
      method_and_args = [key.shift.to_sym]
      case method_and_args[0]
      when :event
        if key.size > 0 && self.respond_to?(key.first)
          method_and_args = [key.shift]
        end
        method_and_args << key
        
      when :progress
        method_and_args << payload.progress
        method_and_args << payload.description
        
      when :runtime
        method_and_args << payload.runtime
        
      when :reply
        
      when :update
        
      when :error
        
      when :log
        method_and_args << payload.message
        method_and_args << payload.level
        
      else
        method_and_args << data if method(method_and_args[0]).arity == 1
      end
      
      return method_and_args
    end
    
    def call(meth, args)
      run_callbacks :call do
        if args.empty?
          send(meth)
        else
          send(meth, *args)
        end
      end
    end
    
    def progress(pct)
      # :noop
    end
    
    def runtime(seconds)
      # :noop
    end
    
    def event(type)
      # :noop
    end
    
    def log(message, level)
      # :noop
    end
    
  end
  
  class GenericListener < Listener
    
  end
end
