class SandwichMaker
  
end

class SandwichEater
  
end

module Cloudist
  class << self
    @@workers = {}
    
    def handle(*queue_names)
      class << queue_names
        def with(handler)
          self.each do |queue_name|
            ((@@workers[queue_name.to_s] ||= []) << handler).uniq!
          end
        end
      end
      queue_names
    end
    
    def use(handler)
      proxy = handler.new
      class << proxy
        def to(queue_name)
          ((@@workers[queue_name.to_s] ||= []) << self.class).uniq!
        end
      end
      proxy
    end
    
    def workers
      @@workers
    end
  end
end

Cloudist.handle('make.sandwich', 'eat').with(SandwichMaker)
Cloudist.use(SandwichEater).to('eat.sandwich')

p Cloudist.workers
# >> {"eat"=>[SandwichMaker], "make.sandwich"=>[SandwichMaker], "eat.sandwich"=>[SandwichEater]}
