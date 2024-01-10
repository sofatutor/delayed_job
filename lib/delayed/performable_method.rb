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

    def kwargs
      check_kwargs
      @kwargs || {}
    end

    def args
      check_kwargs
      @args
    end

    def perform
      object.send(method_name, *args, **kwargs) if object
    end

    def method(sym)
      object.method(sym)
    end

    # rubocop:disable MethodMissing
    def method_missing(symbol, ...)
      object.send(symbol, ...)
    end
    # rubocop:enable MethodMissing

    def respond_to?(symbol, include_private = false)
      super || object.respond_to?(symbol, include_private)
    end

    protected

    def check_kwargs
      # Convert jobs created before the kwargs patch.
      if !@kwargs && @args.last.respond_to?(:to_hash)
        @kwargs = @args.pop.to_hash
      end
    end
  end
end
