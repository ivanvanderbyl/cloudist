module EventMachine
  class Iterator

    def initialize(container)
      @container = container
    end

    def each(work, done=proc{})
      do_work = proc {
        if @container && !@container.empty?
          work.call(@container.shift)
          EM.next_tick(&do_work)
        else
          done.call
        end
      }
      EM.next_tick(&do_work)
    end

    def map(work, done=proc{})
      mapped = []
      map_work = proc { |n| mapped << work.call(n) }
      map_done = proc { done.call(mapped) }
      each(map_work, map_done)
    end
  end
end
