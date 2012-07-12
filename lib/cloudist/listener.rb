require "active_support"
module Cloudist
  class Listener
    include ActiveSupport::Callbacks

    attr_reader :job_queue_name, :payload
    class_attribute :job_queue_names

    class << self
      def listen_to(*job_queue_names)
        self.job_queue_names = job_queue_names.map { |q| Utils.reply_prefix(q) }
      end

      def subscribe(queue_name)
        raise RuntimeError, "You can't subscribe until EM is running" unless EM.reactor_running?

        reply_queue = Cloudist::ReplyQueue.new(queue_name)
        reply_queue.subscribe do |request|
          instance = Cloudist.listener_instances[queue_name] ||= new
          instance.handle_request(request)
        end

        queue_name
      end

      def before(*args, &block)
        set_callback(:call, :before, *args, &block)
      end

      def after(*args, &block)
        set_callback(:call, :after, *args, &block)
      end
    end

    define_callbacks :call, :rescuable => true

    def handle_request(request)
      @payload = request.payload
      key = [payload.message_type.to_s, payload.headers[:event]].compact.join(':')

      meth, *args = handle_key(key)

      if meth.present? && self.respond_to?(meth)
        if method(meth).arity <= args.size
          call(meth, args.first(method(meth).arity))
        else
          raise ArgumentError, "Unable to fire callback (#{meth}) because we don't have enough args"
        end
      end
    end

    def id
      payload.id
    end

    def data
      payload.body
    end

    def handle_key(key)
      key = key.split(':', 2)
      return [nil, nil] if key.empty?

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
        # method_and_args << Cloudist::SafeError.new(payload)
        method_and_args << Hashie::Mash.new(payload.body)

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

    def error(e)
      # :noop
    end

  end

  class GenericListener < Listener

  end
end
