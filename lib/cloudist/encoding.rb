module Cloudist
  module Encoding
    def encode(message)
      Marshal.dump(message)
    end

    def decode(message)
      Marshal.load(message)
    end
  end
end
