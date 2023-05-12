module Kaze
  # Short alias for the `TokenType` enum.
  alias TT = TokenType

  # Enum consisting of all the possible token types.
  enum TokenType
    # Single-character tokens:

    LEFT_PAREN
    RIGHT_PAREN
    COMMA
    COLON
    DOT
    MINUS
    PERCENT
    PLUS
    QUESTION
    SEMICOLON
    SLASH
    STAR

    # One or two character tokens:

    BANG_EQUAL
    EQUAL
    EQUAL_EQUAL
    GREATER
    GREATER_EQUAL
    LEFT_ARROW
    LESS
    LESS_EQUAL

    # Literals:

    IDENTIFIER
    STRING
    NUMBER

    # Keywords:

    AND
    BEGIN
    BREAK
    CLASS
    DO
    ELSE
    END
    FALSE
    FUN
    FOR
    IF
    LAMBDA
    NIL
    NOT
    OR    
    RETURN
    SELF
    SUPER
    THEN
    TRUE
    VAR
    WHILE

    EOF
  end
end
