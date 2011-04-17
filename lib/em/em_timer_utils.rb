module Cloudist
  module EMTimerUtils
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Trap exceptions leaving the block and log them. Do not re-raise
      def trap_exceptions
        yield
      rescue => e
        em_exception(e)
      end

      def em_exception(e)
        msg = format_em_exception(e)
        log.error "[EM.timer] #{msg}", :exception => e
      end

      def format_em_exception(e)
        # avoid backtrace in /usr or vendor if possible
        system, app = e.backtrace.partition { |b| b =~ /(^\/usr\/|vendor)/ }
        reordered_backtrace = app + system

        # avoid "/" as the method name (we want the controller action)
        row = 0
        row = 1 if reordered_backtrace[row].match(/in `\/'$/)

        # get file and method name
        begin
          file, method = reordered_backtrace[row].match(/(.*):in `(.*)'$/)[1..2]
          file.gsub!(/.*\//, '')
          "#{e.class} in #{file} #{method}: #{e.message}"
        rescue
          "#{e.class} in #{e.backtrace.first}: #{e.message}"
        end
      end

      # One-shot timer
      def timer(duration, &blk)
        EM.add_timer(duration) { trap_exceptions(&blk) }
      end

      # Add a periodic timer. If the now argument is true, run the block
      # immediately in addition to scheduling the periodic timer.
      def periodic_timer(duration, now=false, &blk)
        timer(1, &blk) if now
        EM.add_periodic_timer(duration) { trap_exceptions(&blk) }
      end
    end

    def timer(*args, &blk); self.class.timer(*args, &blk); end
    def periodic_timer(*args, &blk); self.class.periodic_timer(*args, &blk); end
  end
end
