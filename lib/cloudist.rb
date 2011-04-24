require 'uri'
require 'json'# unless defined? ActiveSupport::JSON
require "amqp"
require "logger"
require "digest/md5"
require "uuid"
require "active_support/core_ext/module/delegation"
require "hashie"

$:.unshift File.dirname(__FILE__)

require "em/em_timer_utils"
require "cloudist/core_ext/string"
require "cloudist/core_ext/object"
require "cloudist/core_ext/class"
require "cloudist/errors"

module Cloudist
  
  DEFAULT_TTL = 300
  
  autoload :Utils, "cloudist/utils"
  autoload :Encoding, "cloudist/encoding"
  autoload :Message, 'cloudist/message'
  autoload :Queue, 'cloudist/queue'
  autoload :ReplyQueue, 'cloudist/queues/reply_queue'
  autoload :Application, 'cloudist/application'
  autoload :Request, 'cloudist/request'
  autoload :Messaging, 'cloudist/messaging'
  
  class << self
    # delegate :start, :to => Application
    
    def log
      @@log ||= Logger.new($stdout)
    end

    def log=(log)
      @@log = log
    end
    
    def closing?
      ::AMQP.closing?
    end
    
    # Call this at anytime inside the loop to exit the app.
    def stop_safely
      if EM.reactor_running?
        ::EM.add_timer(0.2) { 
          ::AMQP.stop { 
            ::EM.stop
            puts "\n"
          }
        }
      end
    end
    
    alias :stop :stop_safely
    
    def handle_error(e)
      log.error "#{e.class}: #{e.message}"#, :exception => e
      e.backtrace.each do |line|
        log.error line
      end
    end
  end
  
  include Cloudist::EMTimerUtils
end