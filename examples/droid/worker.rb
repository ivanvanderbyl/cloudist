#!/usr/bin/env ruby
# encoding: UTF-8

require "rubygems"
require "droid"

def log
  Droid.log
end

Droid.new('Sandwhich') do |droid|
  droid.worker('sandwhich.make').subscribe do |req|
    log.debug "headers: #{req.header.headers.inspect}"
    req.reply(:target_received_at => Time.now.to_i)
    req.ack
  end
end
