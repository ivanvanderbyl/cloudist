require 'uri'
if !defined?(JSON) && !defined?(JSON_LOADED)
	require 'json/pure'
end
require "active_support/hash_with_indifferent_access"
require "amqp"
require "mq"
require "logger"

require "cloudist/core_ext/string"
require "cloudist/errors"
require "cloudist/utils"
require "cloudist/basic_queue"
require "cloudist/publisher"
require "cloudist/payload"

module Cloudist
  class << self
    # Start the Cloudist loop
    # Cloudist.start {
    #   
    # }
    def start(settings = {}, &block)
      AMQP.start(settings) do
        self.instance_eval(&block)
      end
    end

    def worker(&block)

    end

    def listener(job, &block)

    end

    def enqueue(job_queue_name, data)

    end

    def stop_safely
      log.debug("Shutting down...")
      ::EM.add_timer(0.2) { 
        ::AMQP.stop { 
          ::EM.stop
          log.debug("Good bye")
        }
      }
    end
    
    alias :stop :stop_safely

    def closing?
      ::AMQP.closing?
    end

    def log
      @logger ||= Logger.new($stdout)
    end
    
    def handle_error(error)
      log.error "#{err.class}: #{err.message}", :exception => err
    end
    
  end
  
end