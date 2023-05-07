require "./token_type"

module Kaze
  # A token in a source file.
  class Token
    # The type of the token.
    property type : TT

    # The token represented in plaintext.
    property lexeme : String

    # The literal of the token, if it exists.
    property literal : (String | Float64)?

    # The line where the token is.
    property line : Int32

    # The column in the line where the token is.
    property column : Int32

    def initialize(@type : TT, @lexeme : String, @literal : (String | Float64)?, @line : Int32, @column : Int32)
    end

    # Converts the token to a string.
    def to_s
      "#{@type} #{@lexeme} #{@literal}"
    end
  end
end
