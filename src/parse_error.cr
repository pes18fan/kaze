module Kaze
  # An exception that occured when parsing the source.
  class ParseError < Exception    # The token at which the error occured.
    property token : Token

    def initialize(@token : Token, message)
      super message
    end
  end
end
