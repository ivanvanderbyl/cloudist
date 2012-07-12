module Cloudist
  class Job
    attr_reader :payload, :reply_queue

    def initialize(payload)
      @payload = payload

      if payload.reply_to
        @reply_queue = ReplyQueue.new(payload.reply_to)
        reply_queue.setup
      else
        @reply_queue = nil
      end
    end

    def id
      payload.id
    end

    def data
      payload.body
    end

    def body
      data
    end

    def log
      Cloudist.log
    end

    def cleanup
      # :noop
    end

    def reply(body, headers = {}, options = {})
      raise ArgumentError, "Reply queue not ready" unless reply_queue

      options = {
        :echo => false
      }.update(options)

      headers = {
        :message_id => payload.id,
        :message_type => "reply"
      }.update(headers)

      reply_payload = Payload.new(body, headers)
      published_headers = reply_queue.publish(reply_payload)

      reply_payload
    end

    # Sends a progress update
    # Inputs: percentage - Integer
    # Optional description, this could be displayed to the user e.g. Resizing image
    def progress(percentage, description = nil)
      reply({:progress => percentage, :description => description}, {:message_type => 'progress'})
    end

    def event(event_name, event_data = {}, options = {})
      event_data ||= {}
      reply(event_data, {:event => event_name, :message_type => 'event'}, options)
    end

    def safely(&blk)
      yield
    rescue Exception => e
      handle_error(e)
    end

    def handle_error(e)
      reply({:exception => e.class.name.to_s, :message => e.message.to_s, :backtrace => e.backtrace}, {:message_type => 'error'})
    end

    def method_missing(meth, *args, &blk)
      if meth.to_s.ends_with?("!")
        event(meth.to_s.gsub(/(!)$/, ''), args.shift)
      else
        super
      end
    end

  end
end
