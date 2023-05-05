require "./expr"
require "./runtime_error"

module Kaze
  # Environment where variable bindings are to be stored.
  class Environment
    # The environment enclosing a new instance.
    property enclosing

    # The values in the environment.
    private property values = Hash(String, VG).new

    def initialize
      @enclosing = nil
    end

    def initialize(@enclosing : Environment)
    end

    # Returns the value of the variable matching `name`'s lexeme.
    # If an enclosing environment exists, it fetches the variable from there.
    # Raises an exception if the requested variable has a value of nil, or if it doesn't exist.
    def get(name : Token) : VG
      if values.has_key?(name.lexeme)
        return values[name.lexeme] unless values[name.lexeme] == nil

        raise RuntimeError.new(name, "Variable \"#{name.lexeme}\" not assigned to a value.")
      end

      unless enclosing.nil?
        return @enclosing.as(Environment).get(name)
      end

      raise RuntimeError.new(name, "Undefined variable \"#{name.lexeme}\".")
    end

    # Assigns a value to an existing variable.
    # If the enclosing environment exists, it assigns the variable present there.
    # Raises an exception if the requested variable doesn't exist.
    def assign(name : Token, value : VG)
      if values.has_key?(name.lexeme)
        values[name.lexeme] = value
        return
      end

      unless @enclosing.nil?
        @enclosing.as(Environment).assign(name, value)
        return
      end

      raise RuntimeError.new(name, "Undefined variable \"#{name.lexeme}\".")
    end

    # Defines a new variable binding.
    # If the variable name is `_`, no definition is done.
    def define(name : String, value : VG)
      values[name] = value unless name == "_"
    end
  end
end
