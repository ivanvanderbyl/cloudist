$:.unshift File.dirname(__FILE__) + '/../lib'
require "rubygems"
require "cloudist"

::Signal.trap('INT') { Cloudist.stop }
::Signal.trap('TERM'){ Cloudist.stop }

job = Cloudist.enqueue('make.sandwich', {:bread => 'wholemeal'})

# p Cloudist.reply('make.sandwich', job.id, {:something => 'good'})

queue = Cloudist::SyncJobQueue.new('make.sandwich')
puts queue
queue.subscribe do
  puts "Got Job"
end