require "./expr"
require "./runtime_error"

module Kaze
  # Environment where variable bindings are to be stored.
  class Environment
    property enclosing
    private property values = Hash(String, VG).new

    def initialize
      @enclosing = nil
    end

    def initialize(@enclosing : Environment)
    end

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

    def define(name : String, value : VG)
      values[name] = value
    end
  end
end