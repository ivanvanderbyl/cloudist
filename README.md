Cloudist
========

Cloudist is a super fast job queue for high demand and scalable tasks. It uses AMQP (RabbitMQ mainly) for message store are
distribution, while providing a simple DSL for handling jobs and responses.

Cloudist can be used within Rails or just about any Ruby app to distribute long running tasks, such as encoding a video, generating PDFs, scraping site data
or even just sending emails. Unlike other job queues (DelayedJob etc) Cloudist does not load your entire Rails stack into memory for every worker, and it is not designed to, instead it
expects all the data your worker requires to be sent in the initial job request. This means your workers stay slim and can scale very quickly and even run on EC2 micros outside your applications
network without any further configuration.

Another way Cloudist differs from other AMQP based job queues like Minion is it allows workers to report events, logs, system stats and replies back to the application which distributed the
job, and unlike database based job queues, there is almost no delay between messages, except network latency of course.

Installation
------------

    gem install cloudist

Or if your app has a Gemfile:
    
    gem 'cloudist'

Usage
-----

Cloudist requires an EventMachine reactor loop and an AMQP connection, so if your application is already using one, or your web server supplies one (for example Thin) these examples will work
out of the box. Otherwise simply wrap everything inside this block:
    
    Cloudist.settings = {:user => 'guest'} # Standard AMQP settings
    Cloudist.start {
      # usual stuff here
      worker {
        # define a worker
      }
    }
    
This will start and AMQP connection and EM loop then yield everything inside it.

In your worker:

    Cloudist.start {
      log.info("Started Worker")

      worker {
        job('make.sandwich') {
          # Fire the started event

          log.info("JOB (#{id}) Make sandwich with #{data[:bread]} bread")
          log.debug(data.inspect)

          EM.defer {
            progress(0)
            started!
            progress(10)
            sleep(1)
            progress(20)
            sleep(5)
            progress(90)
            sleep(1)
            finished!
            progress(100)
          }
        }    
      }
    }
    
In your application:

    job = Cloudist.enqueue('make.sandwich', :bread => "white", :sauce => 'bbq')
    
    Cloudist.start {

      log.info("Dispatching sandwich making job...")
      enqueue('make.sandwich', {:bread => 'white'})

      # Listen to all sandwich jobs
      listen('make.sandwich') {
        progress {
          Cloudist.log.info("Progress: #{data[:progress]}")
        }

        event('started') {
          Cloudist.log.info("Started making sandwich at #{Time.now.to_s}")
        }

        event('finished'){
          Cloudist.log.info("Finished making sandwich at #{Time.now.to_s}")
        }
      }

    }
    
You don't need to listen to responses immediately, if you store the job_id you can listen to responses at any time in the near future.

You can also queue jobs outside an EventMachine loop using Cloudist.enqueue but this will be very slow as it has to connect to your message queue first.

Acknowledgements
-------

Portions of this gem are based on code from the following projects:

- Heroku's Droid gem
- Lizzy
- Minion
- Nanite
- Smith

Contributing to Cloudist
------------------------

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch e.g. git checkout -b feature-my-awesome-idea or bugfix-this-does-not-work
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.
    
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

