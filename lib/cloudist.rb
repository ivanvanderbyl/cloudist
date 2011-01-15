require 'uri'
require 'json'
require "active_support/hash_with_indifferent_access"
require "amqp"
require "mq"
require "logger"
require "digest/md5"

$:.unshift File.dirname(__FILE__)
require "cloudist/core_ext/string"
require "cloudist/errors"
require "cloudist/utils"
require "cloudist/basic_queue"
require "cloudist/job_queue"
require "cloudist/reply_queue"
require "cloudist/publisher"
require "cloudist/payload"
require "cloudist/request"
require "cloudist/worker"
require "cloudist/listener"
require "cloudist/job"

module Cloudist
  class << self
    # Start the Cloudist loop
    # Cloudist.start {
    #   
    # }
    def start(options = {}, &block)
      config = settings.update(options)
      AMQP.start(config) do
        self.instance_eval(&block)
      end
    end

    def worker(options = {}, &block)
      _worker = Cloudist::Worker.new(options)
      _worker.instance_eval(&block)
      return _worker
    end
    
    # Accepts a queue name, same as that given to enqueue.
    # Yields each response along with a job ID.
    # Effectively this listens to all jobs responses
    def listen(job_or_queue_name, &block)
      _listener = Cloudist::Listener.new(job_or_queue_name)
      _listener.subscribe(&block)
      return _listener
    end
    
    # Returns Job instance
    # Use Job#id to reference job later on.
    def enqueue(job_queue_name, data = nil)
      raise EnqueueError, "Incorrect arguments, you must include data when enquing job" if data.nil?
      # TODO: Detect if inside loop, if not use bunny sync
      Cloudist::Publisher.enqueue(job_queue_name, data)
    end

    def stop_safely
      ::EM.add_timer(0.2) { 
        ::AMQP.stop { 
          ::EM.stop
        }
      }
    end
    
    alias :stop :stop_safely

    def closing?
      ::AMQP.closing?
    end

    def log
      @@log ||= Logger.new($stdout)
    end
    
    def log=(log)
      @@log = log
    end
    
    def handle_error(e)
      log.error "#{e.class}: #{e.message}"#, :exception => e
      log.error e.backtrace.join("\n")
    end
    
    def version
      @@version ||= File.read(File.dirname(__FILE__) + '/../VERSION').strip
    end
    
    def default_settings
      uri = URI.parse(ENV["AMQP_URL"] || 'amqp://guest:guest@localhost:5672/')
      {
        :vhost => uri.path,
        :host => uri.host,
        :user => uri.user,
        :port => uri.port || 5672,
        :pass => uri.password
      }
    rescue Object => e
      raise "invalid AMQP_URL: (#{uri.inspect}) #{e.class} -> #{e.message}"
    end
    
    def settings
      @@settings ||= default_settings
    end
    
    def settings=(settings_hash)
      @@settings = default_settings.update(settings_hash)
    end
    
    def signal_trap!
      ::Signal.trap('INT') { Cloudist.stop }
      ::Signal.trap('TERM'){ Cloudist.stop }
    end
    
  end
  
end