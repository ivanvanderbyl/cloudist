Cloudist
========

Cloudist is a simple, highly scalable job queue for Ruby applications, it can run within Rails, DaemonKit or your own custom application. Cloudist uses AMQP (RabbitMQ mainly) for transport and provides a simple DSL for queuing jobs and receiving responses including logs, exceptions and job progress.

Cloudist can be used to distribute long running tasks such as encoding a video, generating PDFs, scraping site data
or even just sending emails. Unlike other job queues (DelayedJob etc) Cloudist does not load your entire Rails stack into memory for every worker, and it is not designed to, instead it expects all the data your worker requires to complete a job to be sent in the initial job request. This means your workers stay slim and can scale very quickly and even run on EC2 micros outside your applications environment without any further configuration.

Installation
------------

    gem install cloudist

Or if your app has a Gemfile:
    
    gem 'cloudist'

Usage
-----

Cloudist requires an EventMachine reactor loop and an AMQP connection, so if your application is already using one, or your web server supplies one (for example Thin) these examples will work out of the box. Otherwise simply wrap everything inside this block:
    
    Cloudist.start {
      # usual stuff here
      job('make.sandwich') {
        # define a job handler
      }
    }
    
This will start and AMQP connection and EM loop then yield everything inside it.

In your worker:

    Cloudist.start {
      log.info("Started Worker")

      job('make.sandwich') {
        log.info("JOB (#{id}) Make sandwich with #{data[:bread]} bread")

        job.started!

        (1..20).each do |i|
          job.progress(i * 5)
          sleep(1)
        end
        job.finished!
      }

    }
    
In your application:
    
    Cloudist.start {

      log.info("Dispatching sandwich making job...")
      
      Cloudist.enqueue('make.sandwich', {:bread => 'white', :sandwich_number => 1})

      # Listen to all sandwich jobs
      listen('make.sandwich') {
        everything {
          Cloudist.log.info("#{headers[:message_type]} - Job ID: #{job_id}")
        }
        
        # This will contain any exceptions which are raised while processing the job, which will halt the job
        error { |e|
          Cloudist.log.error(e.inspect)
          Cloudist.log.error(e.backtrace.inspect)
          
          # Exit on failure
          Cloudist.stop
        }
        
        # Process progress updates
        progress {
          Cloudist.log.info("Progress: #{data[:progress]}")
        }
        
        event('started') {
          Cloudist.log.info("Started making sandwich at #{Time.now.to_s}")
        }

        event('finished'){
          Cloudist.log.info("Finished making sandwich at #{Time.now.to_s}")
          # Exit when done
          Cloudist.stop
        }
      }

    }
    

If your application provides an AMQP.start loop already, you can skip the Cloudist.start

Configuration
-------------

The only configuration required to get going are the AMQP settings, these can be set in two ways:

1. Using the `AMQP_URL` environment variable with value of `amqp://username:password@localhost:5672/vhost`

2. Updating the settings hash manually:
    
    
    Cloudist.settings = {:user => 'guest', :pass => 'password', :vhost => '/', :host => 'localhost', :port => 5672}
    

Acknowledgements
----------------

Portions of this gem are based on code from the following projects:

- Heroku's Droid gem
- Lizzy
- Minion

Contributing to Cloudist
------------------------

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch e.g. git checkout -b feature-my-awesome-idea or bugfix-this-does-not-work
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

Authors
-------

Ivan Vanderbyl - [@IvanVanderbyl](http://twitter.com/IvanVanderbyl) - [Blog](http://ivanvanderbyl.github.com/)

Copyright
---------

Copyright (c) 2011 Ivan Vanderbyl. 

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

