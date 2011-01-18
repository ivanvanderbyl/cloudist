module Cloudist
  class Callback
    include Cloudist::CallbackMethods
    
    attr_reader :payload, :source

    def initialize(source)
      @source = source
    end
    
    def call(payload)
      @payload = payload
      instance_eval(&source)
    end
  end
end
