require "./token"

module Kaze
  # An error that occured during runtime.
  class RuntimeError < Exception
    # The token at which the error occured.
    property token : Token

    def initialize(@token : Token, message)
      super message
    end
  end
end