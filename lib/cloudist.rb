require "json"
require "amqp"
require "mq"

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
    
  end
  
end