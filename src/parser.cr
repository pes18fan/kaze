require "./token"
require "./expr"
require "./stmt"

module Kaze
  # The language parser.
  class Parser
    # Expression grammar:
    # expression      -> lambda ;

    # arguments       -> expression ( "," expression )* ;

    # lambda          -> "lambda" parameters ":" assignment ;
    # assignment      -> IDENTIFIER "=" assignment | ternary ;
    # ternary         -> ( logic_or "?" difference ":" difference ) | logic_or ;
    # logic_or        -> logic_and ( "or" logic_and )* ;
    # logic_and       -> equality ( "and" equality )* ;
    # equality        -> comparison ( ( "!=" | "==" ) comparison )* ;
    # comparison      -> difference ( ( "<" | "<=" | ">=" | ">" ) difference )* ;
    # difference      -> sum ( "-" sum )* ;
    # sum             -> difference ( "+" difference )* ;
    # product         -> quotient ( "*" quotient )* ;
    # quotient        -> modulo ( "/" modulo )* ;
    # modulo          -> unary ( "%" unary )* ;
    # unary           -> ( "!" | "-" ) unary | primary ;
    # call            -> primary ( "(" arguments? ")" )* ;
    # primary         -> NUMBER | STRING | IDENTIFIER | "true" | "false" | "nil" | "(" expression ")" ;

    # Parser grammar:
    # program         -> declaration* EOF ;

    # declaration     -> fun_decl | var_decl | statement ;

    # fun_decl        -> "fun" function ;
    # function        -> IDENTIFIER ( "<-" parameters )? block ;
    # parameters      -> IDENTIFIER ( "," IDENTIFIER )* ;
    # var_decl        -> "var" IDENTIFIER ( "=" expression )? ;

    # statement       -> expr_stmt | for_stmt | if_stmt | println_stmt | return_stmt | while_stmt | block ;

    # if_stmt         -> "if" expression "then" statement ( "else" statement )? ;
    # expr_stmt       -> call | assign ;
    # for_stmt        -> "for" ( var_decl | expr_stmt )? ";" expression? ";" expression ( "do" statement | block ) ;
    # println_stmt    -> "println" expression ;
    # return_stmt     -> "return" expression? ;
    # while_stmt      -> "while" expression ( "do" statement | block ) ;
    # block           -> "begin" declaration* "end"

    # An exception that occured when parsing the source.
    private class ParseError < Exception
    end

    # Tokens obtained from the scanner.
    private getter tokens

    # True if in a REPL session.
    private getter repl

    # Tokens to implcitly end a block at.
    private getter implicit_end_block_at = [
      TT::EOF,
      TT::ELSE,
    ]

    # Current position of the parser in the token list.
    private property current = 0

    def initialize(@tokens : Array(Token), @repl : Bool)
    end

    def parse : Array(Stmt) | (Stmt | Expr)?
      statements = Array(Stmt).new

      until at_end?
        dec = declaration

        if @repl
          begin
            return dec
          rescue err : ParseError
            return nil
          end
        end

        statements.push(dec.as(Stmt)) unless dec.nil?
      end

      statements
    end

    # Returns the parsed expression.
    private def expression : Expr
      assignment
    end

    private def declaration : (Stmt | Expr)?
      begin
        return function("function") if match?(TT::FUN)
        return var_declaration if match?(TT::VAR)
        return statement
      rescue err : ParseError
        synchronize
        return nil
      end
    end

    private def statement : Stmt | Expr
      return for_statement if match?(TT::FOR)
      return if_statement if match?(TT::IF)
      return println_statement if match?(TT::PRINTLN)
      return return_statement if match?(TT::RETURN)
      return while_statement if match?(TT::WHILE)
      return Stmt::Block.new(block) if match?(TT::BEGIN)
      expression_statement
    end

    # Parses a for loop by desugaring it into a while loop.
    private def for_statement : Stmt
      initializer = uninitialized (Stmt | Expr)?

      if match?(TT::SEMICOLON)
        initializer = nil
      elsif match?(TT::VAR)
        initializer = var_declaration
      else
        initializer = expression_statement
      end
      consume(TT::SEMICOLON, "Expect \";\".") unless previous.type == TT::SEMICOLON

      condition : Expr? = nil
      unless check?(TT::SEMICOLON)
        condition = expression
      end
      consume(TT::SEMICOLON, "Expect \";\" after loop condition.")

      increment : Expr? = nil
      unless check?(TT::DO) || check?(TT::BEGIN)
        increment = expression
      end
      consume(TT::DO, "Expect \"do\" or \"begin\" after for clauses.") unless check?(TT::BEGIN)

      body = as_stmt(statement, "Expect statement.")

      if increment != nil
        body = Stmt::Block.new(
          [
            body,
            Stmt::Var.new(Token.new(TT::IDENTIFIER, "_", nil, peek.line), increment.as(Expr)),
          ]
        )
      end

      if condition == nil
        condition = Expr::Literal.new(true)
      end
      body = Stmt::While.new(condition.as(Expr), body)

      if initializer != nil
        body = Stmt::Block.new(
          [
            as_stmt(initializer, "Expect initializer to be statement."),
            body,
          ]
        )
      end

      body
    end

    private def if_statement : Stmt
      condition = expression
      in_block = check?(TT::BEGIN)

      consume(TT::THEN, "Expect \"then\" or \"begin\" after if condition.") unless in_block

      then_branch = as_stmt(statement, "Expect statement.")
      else_branch = nil

      if match?(TT::ELSE)
        if in_block
          else_branch = Stmt::Block.new(block)
        else
          else_branch = as_stmt(statement, "Expect statement.")
        end
      end

      Stmt::If.new(condition, then_branch, else_branch)
    end

    private def println_statement : Stmt
      expr = expression
      Stmt::Println.new(expr)
    end

    private def return_statement : Stmt
      keyword = previous
      value = expression
      Stmt::Return.new(keyword, value)
    end

    private def var_declaration : Stmt
      name = consume(TT::IDENTIFIER, "Expect variable name.")

      initializer : Expr? = nil
      if match?(TT::EQUAL)
        initializer = expression
      end

      return Stmt::Var.new(name, initializer)
    end

    private def while_statement : Stmt
      condition = expression

      consume(TT::DO, "Expect \"do\" or \"begin\" after condition.") unless check?(TT::BEGIN)

      body = as_stmt(statement, "Expect statement.")

      Stmt::While.new(condition, body)
    end

    private def expression_statement : Expr | Stmt
      expr = expression
      return expr if @repl

      if expr.is_a?(Expr::Call) || expr.is_a?(Expr::Assign)
        return Stmt::Expression.new(expr)
      end
      
      raise error(peek, "Unexpected expression.")
    end

    private def function(kind : String) : Stmt::Function
      name = consume(TT::IDENTIFIER, "Expect #{kind} name.")

      # consume the left arrow UNLESS the next token is a begin keyword, which indicates that there are no params
      consume(TT::LEFT_ARROW, "Expect \"<-\" after #{kind} name.") unless peek.type == TT::BEGIN

      parameters = Array(Token).new

      unless check?(TT::BEGIN)
        loop do
          if parameters.size >= 255
            error(peek, "Can't have more than 255 parameters.")
          end

          parameters << consume(TT::IDENTIFIER, "Expect parameter name.")

          break unless match?(TT::COMMA)
        end
      end

      consume(TT::BEGIN, "Expect \"begin\" before #{kind} body.")
      body = block

      Stmt::Function.new(name, parameters, body)
    end

    private def block : Array(Stmt)
      statements = Array(Stmt).new

      until check?(TT::END) || at_end?
        # Return early if a token requring an implicit end (for example, "else") was found.
        if implicit_end_block_needed?
          return statements
        end

        statements.push(as_stmt(declaration, "Expect statement."))
      end

      # throw an error if a block containing a return statement doesn't have it as the last element
      if statements.any? { |stmt| stmt.is_a?(Stmt::Return) } && statements.last.is_a?(Stmt::Return) == false
        error(peek, "Return statements must appear in the end of a block.")
      end

      consume(TT::END, "Expect \"end\" after block.")

      statements
    end

    private def assignment : Expr
      expr = lambda

      if match?(TT::EQUAL)
        equals = previous
        value = assignment

        if expr.is_a?(Expr::Variable)
          name = expr.as(Expr::Variable).name
          return Expr::Assign.new(name, value)
        end

        raise error(equals, "Invalid assignment target.")
      end

      expr
    end

    private def lambda : Expr
      if match?(TT::LAMBDA)
        parameters = Array(Token).new

        unless check?(TT::COLON)
          loop do
            if parameters.size >= 255
              error(peek, "Can't have more than 255 parameters.")
            end

            parameters << consume(TT::IDENTIFIER, "Expect parameter name.")

            break unless match?(TT::COMMA)
          end
        end

        consume(TT::COLON, "Expect \":\" after parameters.")
        body = Stmt::Return.new(previous, expression)

        return Expr::Lambda.new(parameters, body)
      end

      ternary
    end

    private def ternary : Expr
      expr = or

      if match?(TT::QUESTION)
        left = difference
        consume(TT::COLON, "Expect \":\" after expression.")
        right = difference

        return Expr::Ternary.new(expr, left, right)
      end

      expr
    end

    private def or : Expr
      expr = and

      while match?(TT::OR)
        operator = previous
        right = and
        expr = Expr::Logical.new(expr, operator, right)
      end

      expr
    end

    private def and : Expr
      expr = equality

      while match?(TT::AND)
        operator = previous
        right = equality
        expr = Expr::Logical.new(expr, operator, right)
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
      expr = modulo

      while match?(TT::SLASH)
        operator = previous
        right = modulo

        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    private def modulo : Expr
      expr = unary

      while match?(TT::PERCENT)
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

      call
    end

    private def finish_call(callee : Expr) : Expr
      arguments = Array(Expr).new

      # don't try to parse args if right paren was found immediately
      unless check?(TT::RIGHT_PAREN)
        loop do
          if arguments.size >= 255
            error(peek, "Cannot have more than 255 arguments.")
          end

          arguments.push(expression)
          break unless match?(TT::COMMA)
        end
      end

      paren = consume(TT::RIGHT_PAREN, "Expect \"(\" after arguments.")

      Expr::Call.new(callee, paren, arguments)
    end

    private def call : Expr
      expr = primary

      loop do
        if match?(TT::LEFT_PAREN)
          expr = finish_call(expr)
        else
          break
        end
      end

      expr
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

    private def implicit_end_block_needed? : Bool
      !!(@implicit_end_block_at.find { |i| i == peek.type })
    end

    private def consume(type : TT, message : String) : Token
      return advance if check?(type)

      raise error(peek, message)
    end

    private def as_stmt(stmt : (Stmt | Expr)?, message : String)
      begin
        return stmt.as(Stmt)
      rescue err : TypeCastError
        raise error(peek, message)
      end
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

    private def peek_next : Token
      @tokens[current + 1]
    end

    private def previous : Token
      @tokens[current - 1]
    end

    private def error(token : Token, message : String) : ParseError
      Program.error(token, message)
      ParseError.new
    end

    private def synchronize
      advance

      until at_end?
        return if previous.type == TT::END

        case peek.type
        when TT::CLASS, TT::FUN, TT::VAR, TT::FOR, TT::IF, TT::WHILE, TT::PRINTLN, TT::RETURN
          return
        end

        advance
      end
    end
  end
end
