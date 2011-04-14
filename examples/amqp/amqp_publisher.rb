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

    EM.defer do
      10000.times { |i|
        log "Publishing message #{i+1}"
        if i % 1000 == 0
          puts "Sleeping..."
          sleep(1)
        end
        exchange.publish "Hello, world! - #{i+1}"#, :routing_key => queue.name
      }
    end
  end  
end
