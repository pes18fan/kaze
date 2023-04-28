require "./token"
require "./main"

module Kaze
  # A scanner that scan a file or line for tokens, parses and returns them.
  class Scanner
    # The source that the scanner scans. May be a file or a line in the REPL.
    private property source : String

    # An array with the tokens scanned from the source.
    private property tokens = Array(Token).new

    # The starting point of each token.
    private property start = 0

    # The current position of the scanner in a token.
    private property current = 0

    # The line where a token is present.
    private property line = 1

    # All of the reserved keywords.
    @@KEYWORDS : Hash(String, TT) = {
      "and"     => TT::AND,
      "class"   => TT::CLASS,
      "else"    => TT::ELSE,
      "end"     => TT::END,
      "false"   => TT::FALSE,
      "for"     => TT::FOR,
      "fun"     => TT::FUN,
      "if"      => TT::IF,
      "nil"     => TT::NIL,
      "or"      => TT::OR,
      "println" => TT::PRINTLN,
      "return"  => TT::RETURN,
      "super"   => TT::SUPER,
      "this"    => TT::THIS,
      "true"    => TT::TRUE,
      "var"     => TT::VAR,
      "while"   => TT::WHILE,
    }

    def initialize(source : String)
      @source = source
    end

    # Scans the file for tokens until the end of the file.
    def scan_tokens : Array(Token)?
      until at_end?
        # We are at the beginning of the next lexeme.
        @start = @current
        scan_token

        return if Kaze::Program.had_error
      end

      tokens.push(Token.new(TT::EOF, "", nil, @line))
      tokens
    end

    # Parses a token.
    private def scan_token
      c = advance

      case c
      when '('
        add_token(TT::LEFT_PAREN)
      when ')'
        add_token(TT::RIGHT_PAREN)
      when '?'
        add_token(TT::QUESTION)
      when ':'
        add_token(TT::COLON)
      when ','
        add_token(TT::COMMA)
      when '.'
        add_token(TT::DOT)
      when '-'
        add_token(TT::MINUS)
      when '+'
        add_token(TT::PLUS)
      when '*'
        add_token(TT::STAR)
      when '/'
        if (match?('*'))
          until peek == '*' || at_end?
            advance
          end

          if at_end?
            Kaze::Program.error(@line, "Unterminated multiline comment.")
            return
          end

          unless match?('/')
            advance

            if at_end?
              Kaze::Program.error(@line, "Unterminated multiline comment.")
              return
            end
          end
        end

        if (match?('/'))
          until peek == '\n' || at_end?
            advance
          end
        else
          add_token(TT::SLASH)
        end
      when '!'
        add_token(match?('=') ? TT::BANG_EQUAL : TT::BANG)
      when '='
        add_token(match?('=') ? TT::EQUAL_EQUAL : TT::EQUAL)
      when '<'
        if match?('-')
          add_token(TT::LEFT_ARROW)
        elsif match?('=')
          add_token(TT::LESS_EQUAL)
        else
          add_token(TT::LESS)
        end
      when '>'
        add_token(match?('=') ? TT::GREATER_EQUAL : TT::GREATER)
      when ' ', '\r', '\t'
        # ignore whitespace
      when '\n'
        add_token(TT::NEWLINE)
        @line += 1
      when '"'
        string
      else
        if digit?(c)
          number
        elsif alpha?(c)
          identifier
        else
          Kaze::Program.error(@line, "Unexpected character.")
          return
        end
      end
    end

    # Helper Methods

    # Parses an identifier.
    private def identifier
      while alphanumeric?(peek)
        advance
      end

      text = source[@start...@current]
      type : TT? = @@KEYWORDS[text]?
      type = TT::IDENTIFIER if type == nil

      if type == TT::RETURN
        @return_found = true
      end

      add_token(type.as(TT))
    end

    # Parses a number literal, as a Float64.
    private def number
      while digit?(peek)
        advance
      end

      if peek == '.' && digit?(peek_next)
        # consume the .
        advance

        while digit?(peek)
          advance
        end
      end

      add_token(TT::NUMBER, source[@start...@current].to_f64)
    end

    # Parses a string literal.
    private def string
      while peek != '"' && !at_end?
        @line += 1 if peek == '\n'
        advance
      end

      if at_end?
        Kaze::Program.error(@line, "Unterminated string.") if at_end?
        return
      end

      # the closing ".
      advance

      # trim the surrounding quotes
      value = source[(@start + 1)...(@current - 1)]
      add_token(TT::STRING, value)
    end

    # Returns true if the next character is equal to `expected`.
    private def match?(expected : Char) : Bool
      return false if at_end?
      return false if source[@current] != expected

      @current += 1
      return true
    end

    # Returns the next character without moving the scanner ahead.
    private def peek : Char
      return '\0' if at_end?
      return source[@current]
    end

    # Returns the next character's next character without moving the scanner ahead.
    private def peek_next : Char
      return '\0' if @current + 1 >= source.size
      return source[@current + 1]
    end

    # Returns true if `c` is a letter or an underscore.
    private def alpha?(c : Char) : Bool
      return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
    end

    # Returns true if `c` is alphanumeric.
    private def alphanumeric?(c : Char) : Bool
      return alpha?(c) || digit?(c)
    end

    # Returns true if `c` is a digit.
    private def digit?(c : Char) : Bool
      c >= '0' && c <= '9'
    end

    # Returns true if @current is higher than the size of the @source.
    private def at_end? : Bool
      @current >= @source.size
    end

    # Increments @current by 1 and returns the current character.
    private def advance : Char
      old_curr = @current
      @current += 1
      return source[old_curr]
    end

    # Adds a token without a literal.
    private def add_token(type : TT)
      add_token(type, nil)
    end

    # Adds a token with a literal.
    private def add_token(type : TT, literal : (String | Float64)?)
      text = source[@start...@current]
      tokens.push(Token.new(type, text, literal, @line))
    end
  end
end
