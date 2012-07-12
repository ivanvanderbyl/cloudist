require 'cloudist/core_ext/kernel'
require 'cloudist/core_ext/module'

# Extracted from ActiveSupport 3.0
class Class

  # Taken from http://coderrr.wordpress.com/2008/04/10/lets-stop-polluting-the-threadcurrent-hash/
  def thread_local_accessor name, options = {}
    m = Module.new
    m.module_eval do
      class_variable_set :"@@#{name}", Hash.new {|h,k| h[k] = options[:default] }
    end
    m.module_eval %{
      FINALIZER = lambda {|id| @@#{name}.delete id }

      def #{name}
        @@#{name}[Thread.current.object_id]
      end

      def #{name}=(val)
        ObjectSpace.define_finalizer Thread.current, FINALIZER  unless @@#{name}.has_key? Thread.current.object_id
        @@#{name}[Thread.current.object_id] = val
      end
    }

    class_eval do
      include m
      extend m
    end
  end


  # Declare a class-level attribute whose value is inheritable by subclasses.
  # Subclasses can change their own value and it will not impact parent class.
  #
  #   class Base
  #     class_attribute :setting
  #   end
  #
  #   class Subclass < Base
  #   end
  #
  #   Base.setting = true
  #   Subclass.setting            # => true
  #   Subclass.setting = false
  #   Subclass.setting            # => false
  #   Base.setting                # => true
  #
  # In the above case as long as Subclass does not assign a value to setting
  # by performing <tt>Subclass.setting = _something_ </tt>, <tt>Subclass.setting</tt>
  # would read value assigned to parent class. Once Subclass assigns a value then
  # the value assigned by Subclass would be returned.
  #
  # This matches normal Ruby method inheritance: think of writing an attribute
  # on a subclass as overriding the reader method. However, you need to be aware
  # when using +class_attribute+ with mutable structures as +Array+ or +Hash+.
  # In such cases, you don't want to do changes in places but use setters:
  #
  #   Base.setting = []
  #   Base.setting                # => []
  #   Subclass.setting            # => []
  #
  #   # Appending in child changes both parent and child because it is the same object:
  #   Subclass.setting << :foo
  #   Base.setting               # => [:foo]
  #   Subclass.setting           # => [:foo]
  #
  #   # Use setters to not propagate changes:
  #   Base.setting = []
  #   Subclass.setting += [:foo]
  #   Base.setting               # => []
  #   Subclass.setting           # => [:foo]
  #
  # For convenience, a query method is defined as well:
  #
  #   Subclass.setting?       # => false
  #
  # Instances may overwrite the class value in the same way:
  #
  #   Base.setting = true
  #   object = Base.new
  #   object.setting          # => true
  #   object.setting = false
  #   object.setting          # => false
  #   Base.setting            # => true
  #
  # To opt out of the instance writer method, pass :instance_writer => false.
  #
  #   object.setting = false  # => NoMethodError
  def class_attribute(*attrs)
    instance_writer = !attrs.last.is_a?(Hash) || attrs.pop[:instance_writer]

    attrs.each do |name|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def self.#{name}() nil end
        def self.#{name}?() !!#{name} end

        def self.#{name}=(val)
          singleton_class.class_eval do
            remove_possible_method(:#{name})
            define_method(:#{name}) { val }
          end

          if singleton_class?
            class_eval do
              remove_possible_method(:#{name})
              def #{name}
                defined?(@#{name}) ? @#{name} : singleton_class.#{name}
              end
            end
          end
          val
        end

        remove_method :#{name} if method_defined?(:#{name})
        def #{name}
          defined?(@#{name}) ? @#{name} : self.class.#{name}
        end

        def #{name}?
          !!#{name}
        end
      RUBY

      attr_writer name if instance_writer
    end
  end

  private
  def singleton_class?
    # in case somebody is crazy enough to overwrite allocate
    allocate = Class.instance_method(:allocate)
    # object.class always points to a real (non-singleton) class
    allocate.bind(self).call.class != self
  rescue TypeError
    # MRI/YARV/JRuby all disallow creating new instances of a singleton class
    true
  end
end
