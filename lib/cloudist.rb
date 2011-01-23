require 'uri'
require 'json' unless defined? ActiveSupport::JSON
require "active_support/hash_with_indifferent_access"
require "amqp"
require "mq"
require "logger"
require "digest/md5"

$:.unshift File.dirname(__FILE__)
require "cloudist/core_ext/string"
require "cloudist/core_ext/object"
require "cloudist/errors"
require "cloudist/utils"
require "cloudist/queues/basic_queue"
require "cloudist/queues/job_queue"
require "cloudist/queues/reply_queue"
require "cloudist/queues/log_queue"
require "cloudist/publisher"
require "cloudist/payload"
require "cloudist/request"
require "cloudist/callback_methods"
require "cloudist/listener"
require "cloudist/callback"
require "cloudist/callbacks/error_callback"
require "cloudist/job"
require "cloudist/worker"

module Cloudist
  class << self
    
    @@workers = {}
    
    # Start the Cloudist loop
    # 
    #   Cloudist.start {
    #     # Do stuff in here
    #   }
    # 
    # == Options
    # * :user => 'name'
    # * :pass => 'secret'
    # * :host => 'localhost'
    # * :port => 5672
    # * :vhost => /
    # 
    # Refer to default config below for how to set these as defaults
    # 
    def start(options = {}, &block)
      config = settings.update(options)
      AMQP.start(config) do
        self.instance_eval(&block)
      end
    end

    # Define a worker. Must be called inside start loop
    # 
    #   worker {
    #     job('make.sandwich') {}
    #   }
    # 
    # REMOVED
    def worker(&block)
      raise NotImplementedError, "This DSL format has been removed. Please use job('make.sandwich') {} instead."
    end
    
    # Defines a job handler (GenericWorker)
    # 
    #   job('make.sandwich') {
    #     job.started!
    #     # Work hard
    #     sleep(5)
    #     job.finished!
    #   }
    # 
    # Refer to sandwich_worker.rb example
    # 
    def job(queue_name, &block)
      register_worker(queue_name, &block)
    end
    
    # Registers a worker class to handle a specific queue
    # 
    #   Cloudist.handle('make.sandwich', 'eat.sandwich').with(MyWorker)
    # 
    # A standard worker would look like this:
    #   
    #   class MyWorker < Cloudist::Worker
    #     def process
    #       log.debug(data.inspect)
    #     end
    #   end
    # 
    # A new instance of this worker will be created everytime a job arrives
    # 
    # Refer to examples.
    def handle(*queue_names)
      class << queue_names
        def with(handler)
          self.each do |queue_name|
            Cloudist.register_worker(queue_name.to_s, handler)
          end
        end
      end
      queue_names
    end
    
    def register_worker(queue_name, klass = nil, &block)
      job_queue = JobQueue.new(queue_name)
      job_queue.subscribe do |request|
        j = Job.new(request.payload.dup)
        EM.defer do
          begin
            if block_given?
              worker_instance = GenericWorker.new(j, job_queue.q)
              worker_instance.process(&block)
            elsif klass
              worker_instance = klass.new(j, job_queue.q)
              worker_instance.process
            else
              raise RuntimeError, "Failed to register worker, I need either a handler class or block."
            end
            finished = Time.now.utc.to_i
            log.debug("Finished Job in #{finished - request.start} seconds")
            
          rescue Exception => e
            j.handle_error(e)
          end
        end
        j.cleanup
      end
      
      ((@@workers[queue_name.to_s] ||= []) << job_queue).uniq!
    end
    
    # Accepts either a queue name or a job instance returned from enqueue.
    # This method operates in two modes, when given a queue name, it
    # will return all responses regardless of job id so you can use the job
    # id to lookup a database record to update etc.
    # When given a job instance it will only return messages from that job.
    def listen(*queue_names, &block)
      @@listeners ||= []
      queue_names.each do |job_or_queue_name|
        _listener = Cloudist::Listener.new(job_or_queue_name)
        _listener.subscribe(&block)
        @@listeners << _listener
      end
      return @@listeners
    end
    
    # Enqueues a job.
    # Takes a queue name and data hash to be sent to the worker.
    # Returns Job instance
    # Use Job#id to reference job later on.
    def enqueue(job_queue_name, data = nil)
      raise EnqueueError, "Incorrect arguments, you must include data when enquing job" if data.nil?
      # TODO: Detect if inside loop, if not use bunny sync
      Cloudist::Publisher.enqueue(job_queue_name, data)
    end

    # Call this at anytime inside the loop to exit the app.
    def stop_safely
      # ::EM.add_timer(0.2) { 
        ::AMQP.stop { 
          ::EM.stop
        }
      # }
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
    
    def workers
      @@workers
    end
    
    def remove_workers
      @@workers = {}
    end
    
  end
  
end