module Kaze
  # Represents something callable.
  abstract class Callable
    abstract def arity : Int32
    abstract def call(interpreter : Interpreter, arguments : Array(VG)) : VG
    abstract def to_s : String
  end
end
