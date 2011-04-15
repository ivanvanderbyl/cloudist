#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"
require 'amqp'

def amqp_settings
  uri = URI.parse(ENV["AMQP_URL"] || 'amqp://guest:guest@localhost:5672/')
  {
    :vhost => uri.path,
    :host => uri.host,
    :user => uri.user,
    :port => uri.port || 5672,
    :pass => uri.password,
    :heartbeat => 120,
    :logging => false
  }
rescue Object => e
  raise "invalid AMQP_URL: (#{uri.inspect}) #{e.class} -> #{e.message}"
end

p amqp_settings

def log(*args)
  puts args.inspect
end

EM.run do
  puts "Running..."
  AMQP.start(amqp_settings) do |connection|
    log "Connected to AMQP broker"

    channel  = AMQP::Channel.new(connection)
    channel.prefetch(1)
    queue    = channel.queue("test.hello.world")
    exchange = channel.direct
    queue.bind(exchange)
    
    @count = 0
    
    queue.subscribe(:ack => true) do |h, payload|
      puts "--"
      EM.defer {
        # sleep(1)
        @count += 1
        log "Received a message: #{payload} - #{@count}"
        h.ack
      }
    end
    
    # queue.subscribe(:ack => false) do |h, payload|
    #   @count += 1
    #   log "Received a message: #{payload} - #{@count}"
    # end
  end  
end
