require "./token"
require "./expr"

module Kaze
  # The language parser.
  class Parser
    # An exception that occured when parsing the source.
    private class ParseError < Exception
    end

    private getter tokens
    private property current = 0

    def initialize(@tokens : Array(Token))
    end

    def parse : Expr?
      begin
        return expression
      rescue err : ParseError
        return nil
      end
    end

    # Returns the parsed expression.
    private def expression : Expr
      ternary
    end

    private def ternary : Expr
      expr = equality

      if match?(TT::QUESTION)
        left = difference
        consume(TT::COLON, "Expect \":\" after expression.")
        right = difference

        return Expr::Ternary.new(expr, left, right)
      end

      expr
    end

    private def equality : Expr
      expr = comparison

      while match?(TT::BANG_EQUAL, TT::EQUAL_EQUAL)
        operator = previous
        right = comparison
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    private def comparison : Expr
      expr = difference

      while match?(TT::GREATER, TT::GREATER_EQUAL, TT::LESS, TT::LESS_EQUAL)
        operator = previous
        right = difference
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    private def difference : Expr 
      expr = sum

      while match?(TT::MINUS)
        operator = previous
        right = sum
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    private def sum : Expr 
      expr = product

      while match?(TT::PLUS)
        operator = previous
        right = product
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    private def product : Expr 
      expr = quotient

      while match?(TT::STAR)
        operator = previous
        right = quotient
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    private def quotient : Expr 
      expr = unary

      while match?(TT::SLASH)
        operator = previous
        right = unary

        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    private def unary : Expr
      if match?(TT::BANG, TT::MINUS)
        operator = previous
        right = unary
        return Expr::Unary.new(operator, right)
      end

      primary
    end

    private def primary : Expr
      return Expr::Literal.new(false) if match?(TT::FALSE)
      return Expr::Literal.new(true) if match?(TT::TRUE)
      return Expr::Literal.new(nil) if match?(TT::NIL)

      if match?(TT::NUMBER, TT::STRING)
        return Expr::Literal.new(previous.literal)
      end

      if match?(TT::LEFT_PAREN)
        expr = expression
        consume(TT::RIGHT_PAREN, "Expect \")\" after expression.")
        return Expr::Grouping.new(expr)
      end

      raise error(peek, "Expect expression.")
    end

    private def match?(*types : TT) : Bool
      types.each do |type|
        if check?(type)
          advance
          return true
        end
      end

      return false
    end

    private def consume(type : TT, message : String) : Token
      return advance if check?(type)

      raise error(peek, message)
    end

    private def check?(type : TT) : Bool
      return false if at_end?
      return peek.type == type
    end

    private def advance : Token
      @current += 1 unless at_end?
      previous
    end

    private def at_end? : Bool
      peek.type == TT::EOF
    end

    private def peek : Token
      @tokens[current]
    end

    private def previous : Token
      @tokens[current - 1]
    end

    private def error(token : Token, message : String) : ParseError
      Kaze::Program.error(token, message)
      ParseError.new
    end

    private def synchronize
      advance

      until at_end?
        return if previous.type == TT::NEWLINE || TT::END

        case peek.type
        when TT::CLASS, TT::FUN, TT::VAR, TT::FOR, TT::IF, TT::WHILE, TT::PRINTLN, TT::RETURN
          return
        end

        advance
      end
    end
  end
end
