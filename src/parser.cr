require "./token"
require "./expr"
require "./stmt"

module Kaze
  # The language parser.
  class Parser
    # Expression grammar:
    # expression      -> assignment ;

    # assignment      -> IDENTIFIER "=" assignment | ternary ;
    # ternary         -> ( equality "?" difference ":" difference ) | equality ;
    # equality        -> comparison ( ( "!=" | "==" ) comparison )* ;
    # comparison      -> difference ( ( "<" | "<=" | ">=" | ">" ) difference )* ;
    # difference      -> sum ( "-" sum )* ;
    # sum             -> difference ( "+" difference )* ;
    # product         -> quotient ( "*" quotient )* ;
    # quotient        -> unary ( "/" unary )*
    # unary           -> ( "!" | "-" ) unary | primary ;
    # primary         -> NUMBER | STRING | IDENTIFIER | "true" | "false" | "nil" | "(" expression ")" ;

    # Parser grammar:
    # program         -> declaration* EOF ;

    # declaration     -> var_decl | statement ;

    # var_decl        -> "var" IDENTIFIER ( "=" expression )? "\n" ;

    # statement       -> expr_stmt | println_stmt ;

    # expr_stmt       -> expression "\n" ;
    # println_stmt    -> "println" expression "\n" ;

    # An exception that occured when parsing the source.
    private class ParseError < Exception
    end

    private getter tokens
    private property current = 0

    def initialize(@tokens : Array(Token))
    end

    def parse : Array(Stmt)
      statements = Array(Stmt).new

      until at_end?
        statements.push(declaration.as(Stmt))
      end

      statements
    end

    # Returns the parsed expression.
    private def expression : Expr
      assignment
    end

    private def declaration : Stmt?
      begin
        return var_declaration if match?(TT::VAR)
        return statement
      rescue err : ParseError
        synchronize
        return nil
      end
    end

    private def statement : Stmt
      return println_statement if match?(TT::PRINTLN)
      expression_statement
    end

    private def println_statement : Stmt
      expr = expression
      consume_newline("Expect '\\n' after expression.")
      Stmt::Println.new(expr)
    end

    private def var_declaration : Stmt
      name = consume(TT::IDENTIFIER, "Expect variable name.")

      initializer : Expr? = nil
      if match?(TT::EQUAL)
        initializer = expression
      end

      consume_newline("Expect \"\\n\" after variable declaration.")
      return Stmt::Var.new(name, initializer)
    end

    private def expression_statement : Stmt
      expr = expression
      consume_newline("Expect '\\n' after expression.")
      Stmt::Expression.new(expr)
    end

    private def assignment : Expr
      expr = equality

      if match?(TT::EQUAL)
        equals = previous
        value = assignment

        if expr.class == Expr::Variable
          name = expr.as(Expr::Variable).name
          return Expr::Assign.new(name, value)
        end

        raise error(equals, "Invalid assignment target.")
      end

      expr
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
      # Return false, true or nil.
      return Expr::Literal.new(false) if match?(TT::FALSE)
      return Expr::Literal.new(true) if match?(TT::TRUE)
      return Expr::Literal.new(nil) if match?(TT::NIL)

      # Return the literal value.
      return Expr::Literal.new(previous.literal) if match?(TT::NUMBER, TT::STRING)

      return Expr::Variable.new(previous) if match?(TT::IDENTIFIER)

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

    private def consume_newline(message : String) : Token?
      consume(TT::NEWLINE, message) unless Program.loc == 1 || peek.type == TT::EOF
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
