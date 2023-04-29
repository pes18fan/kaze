require "./expr"
require "./runtime_error"

module Kaze
  # Environment where variable bindings are to be stored.
  class Environment
    private property values = Hash(String, VG).new

    def initialize
    end

    def get(name : Token) : VG
      if values.fetch(name.lexeme, nil)
        return values[name.lexeme]
      end

      raise RuntimeError.new(name, "Undefined variable \"#{name.lexeme}\".")
    end

    def assign(name : Token, value : VG)
      if values.fetch(name.lexeme, nil)
        values[name.lexeme] = value
        return
      end

      raise RuntimeError.new(name, "Undefined variable \"#{name.lexeme}\".")
    end

    def define(name : String, value : VG)
      values[name] = value
    end
  end
end