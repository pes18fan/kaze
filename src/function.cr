require "./return"

module Kaze
  # A callable function. It may also be anonymous.
  class Function < Callable
    def initialize(@declaration : Stmt::Function, @closure : Environment, @is_initializer : Bool)
    end

    # Bind `self` to a class instance.
    # Returns a function with `self` in its scope.
    def bind(instance : Instance) : Function
      environment = Environment.new(@closure)
      environment.define("self", instance)
      
      Function.new(@declaration, environment, @is_initializer)
    end

    # The number of arguments the function takes.
    def arity : Int32
      @declaration.params.size
    end

    # Executes the function.
    def call(interpreter : Interpreter, arguments : Array(VG)) : VG
      environment = Environment.new(@closure)

      i = 0
      @declaration.params.each do |param|
        environment.define(param.lexeme, arguments[i])
        i += 1
      end

      begin
        interpreter.execute_block(@declaration.body, environment)
      rescue return_value : Return
        return @closure.get_at(0, "self") if @is_initializer

        return return_value.value
      end

      # Return self if the function is a class initializer.
      return @closure.get_at(0, "self") if @is_initializer

      nil
    end
    
    def to_s : String
      @declaration.name.nil? ? "<lambda fun>" : "<fun #{@declaration.name.as(Token).lexeme}>"
    end
  end
end
