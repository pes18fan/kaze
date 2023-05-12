module Kaze
  # An exception raised by a break statement.
  # Like the return statement, this is a hacky way to implement a control mechanism in loops.
  class Break < Exception
    # The return value.
    property value

    def initialize
    end
  end
end