module Kaze
  alias TT = TokenType

  # Enum consisting of all the possible token types.
  enum TokenType
    # Single-character tokens.
    LEFT_PAREN
    RIGHT_PAREN
    COMMA
    COLON
    DOT
    MINUS
    NEWLINE
    PLUS
    QUESTION
    SLASH
    STAR

    # One or two character tokens.
    BANG
    BANG_EQUAL
    EQUAL
    EQUAL_EQUAL
    GREATER
    GREATER_EQUAL
    LEFT_ARROW
    LESS
    LESS_EQUAL

    # Literals.
    IDENTIFIER
    STRING
    NUMBER

    # Keywords.
    AND
    CLASS
    ELSE
    END
    FALSE
    FUN
    FOR
    IF
    NIL
    OR
    PRINTLN
    RETURN
    SUPER
    THIS
    TRUE
    VAR
    WHILE

    EOF
  end
end
