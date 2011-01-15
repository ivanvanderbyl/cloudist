module Cloudist
  module Utils
    extend self
    
    def generate_queue(exchange_name, second_name=nil)
      second_name ||= $$
      "#{generate_name_for_instance(exchange_name)}.#{second_name}"
    end

    def generate_name_for_instance(name)
      "#{name}.#{Socket.gethostname}"
    end
    
    def generate_reply_to(name)
      "temp.reply.#{name}.#{generate_sym}"
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
  end
end