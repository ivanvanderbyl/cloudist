require 'uri'
require 'json' unless defined? ActiveSupport::JSON
require "amqp"
require "hashie"
require "logger"
require "digest/md5"
require "uuid"

$:.unshift File.dirname(__FILE__)

require "em/em_timer_utils"
require "cloudist/core_ext/string"
require "cloudist/core_ext/object"
require "cloudist/core_ext/class"
require "cloudist/errors"
require "cloudist/utils"
require "cloudist/encoding"
require "cloudist/queues/basic_queue"
require "cloudist/queues/job_queue"
require "cloudist/queues/reply_queue"
require "cloudist/publisher"
require "cloudist/payload"
require "cloudist/request"
require "cloudist/listener"
require "cloudist/job"
require "cloudist/worker"

module Cloudist
  DEFAULT_TTL = 300
  
  class << self
    thread_local_accessor :channels, :default => {}
    thread_local_accessor :workers, :default => {}
    thread_local_accessor :listeners, :default => []
    thread_local_accessor :listener_instances, :default => {}
    
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
    # * :heartbeat => 0
    # * :logging => false
    # 
    # Refer to default config below for how to set these as defaults
    # 
    def start(options = {}, &block)
      config = settings.update(options)
      AMQP.start(config) do
        self.instance_eval(&block) if block_given?
      end
    end
    
    def connection
      AMQP.connection
    end
    
    def connection=(conn)
      AMQP.connection = conn
    end

    # Define a worker. Must be called inside start loop
    # 
    #   worker {
    #     job('make.sandwich') {}
    #   }
    # 
    # REMOVED
    # 
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
    def job(queue_name)
      if block_given?
        block = Proc.new
        register_worker(queue_name, &block)
      else
        raise ArgumentError, "You must supply a block as the last argument"
      end
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
        rescue Exception => e
          j.handle_error(e)
        ensure
          finished = Time.now.utc.to_f
          log.debug("Finished Job in #{finished - request.start} seconds")
          j.reply({:runtime => (finished - request.start)}, {:message_type => 'runtime'})
          j.cleanup
        end
      end
      
      ((self.workers[queue_name.to_s] ||= []) << job_queue).uniq!
    end
    
    # Accepts either a queue name or a job instance returned from enqueue.
    # This method operates in two modes, when given a queue name, it
    # will return all responses regardless of job id so you can use the job
    # id to lookup a database record to update etc.
    # When given a job instance it will only return messages from that job.
    # 
    # DEPRECATED
    # 
    def listen(*queue_names, &block)
      raise NotImplementedError, "This DSL method has been removed. Please use add_listener"
    end
    
    # Adds a listener class
    def add_listener(klass)
      raise ArgumentError, "Your listener must extend Cloudist::Listener" unless klass.superclass == Cloudist::Listener
      raise ArgumentError, "Your listener must declare at least one queue to listen to. Use listen_to 'queue.name'" if klass.job_queue_names.nil?
      
      klass.job_queue_names.each do |queue_name|
        klass.subscribe(queue_name)
      end
      
      self.listeners << klass
      
      return self.listeners
    end
    
    # Enqueues a job.
    # Takes a queue name and data hash to be sent to the worker.
    # Returns Job instance
    # Use Job#id to reference job later on.
    def enqueue(job_queue_name, data = nil)
      raise EnqueueError, "Incorrect arguments, you must include data when enqueuing job" if data.nil?
      # TODO: Detect if inside loop, if not use bunny sync
      Cloudist::Publisher.enqueue(job_queue_name, data)
    end
    
    # Send a reply synchronously
    # This uses bunny instead of AMQP and as such can be run outside
    # of EventMachine and the Cloudist start loop.
    # 
    # Usage: Cloudist.reply('make.sandwich', {:sandwhich_id => 12345})
    # 
    # def reply(queue_name, job_id, data, options = {})
    #   headers = {
    #     :message_id => job_id,
    #     :message_type => "reply",
    #     # :event => 'working',
    #     :message_type => 'reply'
    #   }.update(options)
    # 
    #   payload = Cloudist::Payload.new(data, headers)
    # 
    #   queue = Cloudist::SyncReplyQueue.new(queue_name)
    # 
    #   queue.setup
    #   queue.publish_to_q(payload)
    # end

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
        :pass => uri.password,
        :heartbeat => 0,
        :logging => false
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
    
    def log
      @@log ||= Logger.new($stdout)
    end

    def log=(log)
      @@log = log
    end
    
    alias :install_signal_trap :signal_trap!
    
    def remove_workers
      self.workers.keys.each do |worker|
        self.workers.delete(worker)
      end
    end
    
  end
  
  include Cloudist::EMTimerUtils
end