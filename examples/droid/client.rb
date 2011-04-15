#!/usr/bin/env ruby
# encoding: UTF-8

require "rubygems"
require "droid"

def log
  Droid.log
end

Droid.new('Sandwhich') do |droid|
  droid.listener('sandwhich.make').subscribe do |req|
    # req.publish('sandwhich.make', {:work => "son"})
    p req
  #   # req.publish('example.target', { :checking => Time.now.to_i }) do |req2|
  #   #       log.debug "event_hash should be woot -> #{req2.droid_headers[:event_hash]}"
  #   #       log.info "We're done checking!"
  #   #       Droid.stop_safe
  #   #     end
  end
  Droid.publish('sandwhich.make', {:sent_at => Time.now.to_i, :bread => 'White'})
  # droid.timer(2) {   }
end
