module Cloudist
  module Encoding
    def encode(message)
      # Marshal.dump(message)
      # JSON.dump(message.to_hash)
      message.to_json
    end

    def decode(message)
      raise ArgumentError, "First argument can't be nil" if message.nil?
      return message unless message.is_a?(String)
      # Marshal.load(message)
      JSON.load(message)
    end
  end
end
