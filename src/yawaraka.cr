require "./util"

module Kaze
  # The standard library.
  module Yawaraka
    extend self

    # Macro to create a native function in the library.
    macro create_native_fun(class_name, arity, body)
      class {{ class_name }} < Callable
        def initialize
        end

        def arity : Int32
          {{ arity }}
        end

        def call(interpreter : Interpreter, arguments : Array(VG)) : VG
          {{ body }}
        end

        def to_s : String
          "<native fun>"
        end
      end
    end

    # Creates the standard library functions.

    # print(): Prints to stdout.
    Yawaraka.create_native_fun(Print, 1, 
    begin
      print Util.remove_escape_seqs(Util.stringify(arguments[0]))
    end
    )

    # clock(): Return the number of seconds passed since January 1st, 1970.
    Yawaraka.create_native_fun(Clock, 0, Time.utc.to_unix_ms / 1000)

    # scanln(): Returns input from stdin, with the argument being the prompt.
    Yawaraka.create_native_fun(Scanln, 1,
      begin
        print Util.remove_escape_seqs(arguments[0].to_s)
        gets
      end
    )
  end
end
