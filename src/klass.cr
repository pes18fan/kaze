require "./callable"
require "./instance"
require "./function"

module Kaze
  # Runtime representation of a class.
  class Klass < Callable
    property name : String
    property superclass : Klass?
    private property methods : Hash(String, Function)

    def initialize(@name : String, @superclass : Klass?, @methods : Hash(String, Function))
    end

    def find_method(name : String) : Function?
      if methods.has_key?(name)
        return methods[name]
      end

      unless superclass.nil?
        return superclass.as(Klass).find_method(name)
      end

      nil
    end

    # Arity of a class is zero if it has no `init` method, else the arity equals that of the initializer.
    def arity : Int32
      initializer = find_method("init")
      return 0 if initializer.nil?
      initializer.arity()
    end

    def call(interpreter : Interpreter, arguments : Array(VG)) : VG
      instance = Instance.new(self)
      initializer = find_method("init")

      # Bind `self` to the initializer and call it immediately after.
      unless initializer.nil?
        initializer.bind(instance).call(interpreter, arguments)
      end

      instance
    end

    def to_s : String
      @name
    end
  end
end
