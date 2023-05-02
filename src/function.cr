module Kaze
  class Function < Callable
    def initialize(@declaration : Stmt::Function)
    end

    def arity : Int32
      @declaration.params.size
    end

    def call(interpreter : Interpreter, arguments : Array(VG)) : VG
      environment = Environment.new(interpreter.globals)

      i = 0
      @declaration.params.each do |param|
        environment.define(param.lexeme, arguments[i])
        i += 1
      end

      interpreter.execute_block(@declaration.body, environment)
      nil
    end

    def to_s : String
      "<fun #{@declaration.name.lexeme}>"
    end
  end
end
