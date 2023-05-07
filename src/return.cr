module Kaze
  # An exception raised by a return statement.
  # Note that this is not an actual error, but rather a hacky way to allow getting out of a function scope.
  class Return < Exception
    # The return value.
    property value

    def initialize(@value : VG)
    end
  end
end