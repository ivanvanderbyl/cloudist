require 'uri'
require 'json' unless defined? ActiveSupport::JSON
require "amqp"
require "logger"
require "digest/md5"
require "uuid"
require "active_support/core_ext/module/delegation"

$:.unshift File.dirname(__FILE__)

require "cloudist/core_ext/string"
require "cloudist/core_ext/object"
require "cloudist/core_ext/class"
require "cloudist/errors"

module Cloudist
  
  DEFAULT_TTL = 300
  
  autoload :Utils, "cloudist/utils"
  autoload :Message, 'cloudist/message'
  autoload :Queue, 'cloudist/queue'
  autoload :Application, 'cloudist/application'
  autoload :Hashie, 'hashie'
  
  class << self
    # delegate :start, :to => Application
    
    def log
      @@log ||= Logger.new($stdout)
    end

    def log=(log)
      @@log = log
    end
  end
  
end