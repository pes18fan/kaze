module Kaze
  module Yawaraka
    # Returns the number of milliseconds passed since January 1st 1970.
    class Clock < Callable
      def initialize
      end

      def arity : Int32
        0
      end

      def call(interpreter : Interpreter, arguments : Array(VG)) : VG
        Time.utc.to_unix_ms / 1000
      end

      def to_s : String
        "<native fun>"
      end
    end

    # Returns input from STDIN.
    # Takes an argument as the input prompt.
    class Scanln < Callable
      def initialize
      end

      def arity : Int32
        1
      end

      def call(interpreter : Interpreter, arguments : Array(VG)) : VG
        print arguments[0]
        gets
      end

      def to_s : String
        "<native fun>"
      end
    end
  end
end
