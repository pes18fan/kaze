require "./return"

module Kaze
  class Function < Callable
    def initialize(@declaration : Stmt::Function, @closure : Environment)
    end

    def arity : Int32
      @declaration.params.size
    end

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
        return return_value.value
      end
      nil
    end

    def to_s : String
      "<fun #{@declaration.name.lexeme}>"
    end
  end
end
