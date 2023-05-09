module Kaze
  # Runtime representation of a class instance.
  class Instance
    # The class out of which this instance is born.
    private property klass : KazeClass

    # The fields in this instance.
    private property fields = Hash(String, VG).new

    def initialize(@klass : KazeClass)
    end

    # Returns a field with the key `name`.
    # Raises an exception if the key doesn't exist.
    def get(name : Token) : VG
      if fields.has_key?(name.lexeme)
        return fields[name.lexeme]
      end

      # Look for a method with given name if no field is found.
      method = @klass.find_method(name.lexeme)
      return method.bind(self) unless method.nil?

      raise RuntimeError.new(name, "Undefined property #{name.lexeme}.")
    end

    # Assigns `value` to `name`.
    def set(name : Token, value : VG)
      fields[name.lexeme] = value
    end

    def to_s : String
      "#{klass.name} instance"
    end
  end
end