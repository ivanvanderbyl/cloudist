module Cloudist
  class Error < RuntimeError; end
  class BadPayload < Error; end
  class EnqueueError < Error; end
  class StaleHeadersError < BadPayload; end
  class UnknownReplyTo < RuntimeError; end
  class ExpiredMessage < RuntimeError; end
end
