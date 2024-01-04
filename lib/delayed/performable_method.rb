module Delayed
  class PerformableMethod
    attr_accessor :object, :method_name, :args, :kwargs

    def initialize(object, method_name, args, kwargs = {})
      raise NoMethodError, "undefined method `#{method_name}' for #{object.inspect}" unless object.respond_to?(method_name, true)

      if object.respond_to?(:persisted?) && !object.persisted?
        raise(ArgumentError, "job cannot be created for non-persisted record: #{object.inspect}")
      end

      self.object       = object
      self.args         = args
      self.kwargs       = kwargs
      self.method_name  = method_name.to_sym
    end

    def display_name
      if object.is_a?(Class)
        "#{object}.#{method_name}"
      else
        "#{object.class}##{method_name}"
      end
    end

    def perform
      object.send(method_name, *args, **kwargs) if object
    end

    def method(sym)
      object.method(sym)
    end
    method_def = []
    location = caller_locations(1, 1).first
    file = location.path
    line = location.lineno
    definition = RUBY_VERSION >= '2.7' ? '...' : '*args, &block'
    method_def <<
      "def method_missing(#{definition})" \
        "  object.send(#{definition})" \
        'end'
    module_eval(method_def.join(';'), file, line)
    # rubocop:enable MethodMissing

    def respond_to?(symbol, include_private = false)
      super || object.respond_to?(symbol, include_private)
    end
  end
end
