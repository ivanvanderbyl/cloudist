require "singleton"

module Cloudist
  class Application
    include Singleton
    
    class << self
      def start(options = {}, &block)
        options = instance.settings.update(options)
        AMQP.start(options) do
          instance.setup_reconnect_hook!

          instance.instance_eval(&block) if block_given?
        end
      end
      
      def signal_trap!
        ::Signal.trap('INT') { Cloudist.stop }
        ::Signal.trap('TERM'){ Cloudist.stop }
      end
    end
    
    def settings
      @@settings ||= default_settings
    end
    
    def settings=(settings_hash)
      @@settings = default_settings.update(settings_hash)
    end
    
    def default_settings
      uri = URI.parse(ENV["AMQP_URL"] || 'amqp://guest:guest@localhost:5672/')
      {
        :vhost => uri.path,
        :host => uri.host,
        :user => uri.user,
        :port => uri.port || 5672,
        :pass => uri.password,
        :heartbeat => 5,
        :logging => false
      }
    rescue Object => e
      raise "invalid AMQP_URL: (#{uri.inspect}) #{e.class} -> #{e.message}"
    end
    
    private
    
    def setup_reconnect_hook!
      AMQP.conn.connection_status do |status|
        
        log.debug("AMQP connection status changed: #{status}")
        
        if status == :disconnected
          AMQP.conn.reconnect(true)
        end
      end
    end
    
  end
end
