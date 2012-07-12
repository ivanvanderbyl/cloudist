module Cloudist
  module Utils
    extend self

    def reply_prefix(name)
      "temp.reply.#{name}"
    end

    def log_prefix(name)
      "temp.log.#{name}"
    end

    def stats_prefix(name)
      "temp.stats.#{name}"
    end

    def generate_queue(exchange_name, second_name=nil)
      second_name ||= $$
      "#{generate_name_for_instance(exchange_name)}.#{second_name}"
    end

    def generate_name_for_instance(name)
      "#{name}.#{Socket.gethostname}"
    end

    # DEPRECATED
    def generate_reply_to(name)
      "#{reply_prefix(name)}.#{generate_sym}"
    end

    def generate_sym
      values = [
        rand(0x0010000),
        rand(0x0010000),
        rand(0x0010000),
        rand(0x0010000),
        rand(0x0010000),
        rand(0x1000000),
        rand(0x1000000),
      ]
      "%04x%04x%04x%04x%04x%06x%06x" % values
    end

    def encode_message(object)
      Marshal.dump(object).to_s
    end

    def decode_message(string)
      Marshal.load(string)
    end

    def decode_json(string)
      if defined? ActiveSupport::JSON
        ActiveSupport::JSON.decode string
      else
        JSON.load string
      end
    end

  end
end
