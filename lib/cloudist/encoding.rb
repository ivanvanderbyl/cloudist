module Cloudist
  module Encoding
    def encode(message)
      Marshal.dump(message)
    end

    def decode(message)
      raise ArgumentError, "First argument can't be nil" if message.nil?
      return message unless message.is_a?(String)
      Marshal.load(message)
    end
  end
end
