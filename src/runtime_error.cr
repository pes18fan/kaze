require "./token"

module Kaze
  class RuntimeError < Exception
    property token : Token

    def initialize(@token : Token, message)
      super message
    end
  end
end