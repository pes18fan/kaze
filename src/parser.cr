require "./token"
require "./expr"
require "./stmt"
require "./parse_error"

module Kaze
  # The language parser.
  class Parser
    # Precedence rules going from lowest to highest:
    # Name            Operators       Associativity
    # Equality        == !=           Left to right
    # Comparison      > >= < <=       Left to right
    # Term            - +             Left to right
    # Factor          / *             Left to right
    # Unary           ! -             Right to left
    # Ternary         ?:              Right to left

    # Expression grammar:
    # expression      -> lambda ;

    # arguments       -> expression ( "," expression )* ;

    # lambda          -> "lambda" parameters ":" assignment ;
    # assignment      -> ( call "." )? IDENTIFIER "=" assignment | ternary ;
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
    # call            -> primary ( "(" arguments? ")" | "." IDENTIFIER )* ;
    # primary         -> NUMBER | STRING | IDENTIFIER | "true" | "false" | "nil" | "(" expression ")" ;

    # Parser grammar:
    # program         -> declaration* EOF ;

    # declaration     -> class_decl | fun_decl | var_decl | statement ;

    # class_decl      -> "class" IDENTIFIER "begin" function* "end" ;
    # fun_decl        -> "fun" function ;

    # function        -> IDENTIFIER ( "<-" parameters )? block ;
    # parameters      -> IDENTIFIER ( "," IDENTIFIER )* ;

    # var_decl        -> "var" IDENTIFIER ( "=" expression )? ;

    # statement       -> expr_stmt | for_stmt | if_stmt | return_stmt | while_stmt | block ;

    # if_stmt         -> "if" expression "then" statement ( "else" statement )? ;
    # expr_stmt       -> call | assign ;
    # for_stmt        -> "for" ( var_decl | expr_stmt )? ";" expression? ";" expression ( "do" statement | block ) ;
    # return_stmt     -> "return" expression? ;
    # while_stmt      -> "while" expression ( "do" statement | block ) ;
    # block           -> "begin" declaration* "end"

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

    # Statement list.
    private property statements : Array(Stmt)

    def initialize(@tokens : Array(Token), @repl : Bool)
      @statements = Array(Stmt).new
    end

    # Parse an array of tokens.
    def parse : Array(Stmt) | (Stmt | Expr)?
      until at_end?
        dec = declaration

        if @repl
          begin
            return dec
          rescue err : ParseError
            Program.error(err.token, err.message.as(String))
            return nil
          end
        end

        @statements.push(dec.as(Stmt)) unless dec.nil?
      end

      @statements
    end

    # Parse an expression.
    private def expression : Expr
      assignment
    end

    # Parse a declaration.
    private def declaration : (Stmt | Expr)?
      begin
        return class_declaration if match?(TT::CLASS)
        return function("function") if match?(TT::FUN)
        return var_declaration if match?(TT::VAR)
        return statement
      rescue err : ParseError
        Program.error(err.token, err.message.as(String))
        synchronize
        return nil
      end
    end

    # Parse a class declaration.
    private def class_declaration : Stmt
      name = consume(TT::IDENTIFIER, "Expect class name.")
      consume(TT::BEGIN, "Expect \"begin\" before class body.")

      methods = Array(Stmt::Function).new

      until check?(TT::END) || at_end?
        methods.push(function("method"))
      end

      consume(TT::END, "Expect \"end\" after class body.")

      Stmt::Class.new(name, methods)
    end

    # Parse a function definition.
    private def function(kind : String) : Stmt::Function
      name = consume(TT::IDENTIFIER, "Expect #{kind} name.")

      # consume the left arrow UNLESS the next token is a begin keyword
      # the begin keyword being there indicates that there are no params
      consume(TT::LEFT_ARROW, "Expect \"<-\" after #{kind} name.") unless peek.type == TT::BEGIN

      parameters = Array(Token).new

      unless check?(TT::BEGIN)
        loop do
          if parameters.size >= 255
            raise error(peek, "Can't have more than 255 parameters.")
          end

          parameters << consume(TT::IDENTIFIER, "Expect parameter name.")

          break unless match?(TT::COMMA)
        end
      end

      consume(TT::BEGIN, "Expect \"begin\" before #{kind} body.")
      body = block

      Stmt::Function.new(name, parameters, body)
    end

    # Parse a variable declaration. The initial value may be nil.
    private def var_declaration : Stmt
      name = consume(TT::IDENTIFIER, "Expect variable name.")

      initializer : Expr? = nil
      if match?(TT::EQUAL)
        initializer = expression
      end

      return Stmt::Var.new(name, initializer)
    end

    # Parse a statement.
    private def statement : Stmt | Expr
      return for_statement if match?(TT::FOR)
      return if_statement if match?(TT::IF)
      return return_statement if match?(TT::RETURN)
      return while_statement if match?(TT::WHILE)
      return Stmt::Block.new(block) if match?(TT::BEGIN)
      expression_statement
    end

    # Parse a for loop by desugaring it into a while loop.
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

      body = as_stmt(declaration, "Expect statement.")

      if increment != nil
        body = Stmt::Block.new(
          [
            body,
            Stmt::Var.new(Token.new(TT::IDENTIFIER, "_", nil, peek.line, 0), increment.as(Expr)),
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

    # Parse an if statement. Note that else-if constructs are not available yet.
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

    # Parse a return statement.
    # A return statement must always be at the end of a block.
    # If the next keyword it finds isn't `end`, it checks if the next statement is an expression statement and raises an exception if it is.
    # If that's not the case, it tries to assign an expression as the return value.
    # Since a ParseError is raised if the expression parser tries to parse a statement, we can simply catch that.
    # Then, we can raise a more specific exception, instead of just "Expected expression".
    private def return_statement : Stmt
      keyword = previous
      value = nil
      unless check?(TT::END)
        begin
          if expression_statement_next?
            raise error(keyword, "Return statement must be at the end of a block.")
          end

          value = expression
        rescue err : ParseError
          raise error(keyword, "Return statement must be at the end of a block.")
        end
      end

      Stmt::Return.new(keyword, value)
    end

    # Parse a while loop.
    private def while_statement : Stmt
      condition = expression

      consume(TT::DO, "Expect \"do\" or \"begin\" after condition.") unless check?(TT::BEGIN)

      body = as_stmt(declaration, "Expect statement.")

      Stmt::While.new(condition, body)
    end

    # Parse an expression as a statement, but only if its a function call or an assignment.
    # Returns an expression if in a REPL session.
    private def expression_statement : Expr | Stmt
      expr = expression
      return expr if @repl

      if expr.is_a?(Expr::Call) || expr.is_a?(Expr::Assign) || expr.is_a?(Expr::Set) || expr.is_a?(Expr::Get)
        return Stmt::Expression.new(expr)
      end

      raise error(peek, "Unexpected expression.")
    end

    # Parse a block, beginning with `begin` and terminating with `end`.
    private def block : Array(Stmt)
      statements = Array(Stmt).new

      until check?(TT::END) || at_end?
        # Return early if a token requring an implicit end (for example, "else") was found.
        if implicit_end_block_needed?
          return statements
        end

        statements.push(as_stmt(declaration, "Expect statement."))
      end

      consume(TT::END, "Expect \"end\" after block.")

      statements
    end

    # Parse an assignment expression.
    private def assignment : Expr
      expr = lambda

      if match?(TT::EQUAL)
        equals = previous
        value = assignment

        if expr.is_a?(Expr::Variable)
          name = expr.as(Expr::Variable).name
          return Expr::Assign.new(name, value)
        elsif expr.is_a?(Expr::Get)
          get = expr.as(Expr::Get)
          return Expr::Set.new(get.object, get.name, value)
        end

        raise error(equals, "Invalid assignment target.")
      end

      expr
    end

    # Parse an anonymous lambda function expression.
    private def lambda : Expr
      if match?(TT::LAMBDA)
        parameters = Array(Token).new

        unless check?(TT::COLON)
          loop do
            if parameters.size >= 255
              raise error(peek, "Can't have more than 255 parameters.")
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

    # Parse a ternary operation i.e. the conditional operator.
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

    # Parse a logical OR expression.
    private def or : Expr
      expr = and

      while match?(TT::OR)
        operator = previous
        right = and
        expr = Expr::Logical.new(expr, operator, right)
      end

      expr
    end

    # Parse a logical AND expression.
    private def and : Expr
      expr = equality

      while match?(TT::AND)
        operator = previous
        right = equality
        expr = Expr::Logical.new(expr, operator, right)
      end

      expr
    end

    # Parse an equality expression.
    private def equality : Expr
      expr = comparison

      while match?(TT::BANG_EQUAL, TT::EQUAL_EQUAL)
        operator = previous
        right = comparison
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    # Parse a comparison expression.
    private def comparison : Expr
      expr = difference

      while match?(TT::GREATER, TT::GREATER_EQUAL, TT::LESS, TT::LESS_EQUAL)
        operator = previous
        right = difference
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    # Parse a binary expression of subtraction.
    private def difference : Expr
      expr = sum

      while match?(TT::MINUS)
        operator = previous
        right = sum
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    # Parse a binary expression of addition.
    private def sum : Expr
      expr = product

      while match?(TT::PLUS)
        operator = previous
        right = product
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    # Parse a binary expression of multiplication.
    private def product : Expr
      expr = quotient

      while match?(TT::STAR)
        operator = previous
        right = quotient
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    # Parse a binary expression of division.
    private def quotient : Expr
      expr = modulo

      while match?(TT::SLASH)
        operator = previous
        right = modulo

        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    # Parse a binary expression of modulo i.e. remainder.
    private def modulo : Expr
      expr = unary

      while match?(TT::PERCENT)
        operator = previous
        right = unary

        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    # Parse a unary expression.
    private def unary : Expr
      if match?(TT::NOT, TT::MINUS)
        operator = previous
        right = unary
        return Expr::Unary.new(operator, right)
      end

      call
    end

    # Finish parsing a function call.
    # This parses the arguments in a function call.
    # It spits out an error if there are 255 or more args.
    private def finish_call(callee : Expr) : Expr
      arguments = Array(Expr).new

      # don't try to parse args if right paren was found immediately
      unless check?(TT::RIGHT_PAREN)
        loop do
          if arguments.size >= 255
            raise error(peek, "Cannot have more than 255 arguments.")
          end

          arguments.push(expression)
          break unless match?(TT::COMMA)
        end
      end

      paren = consume(TT::RIGHT_PAREN, "Expect \"(\" after arguments.")

      Expr::Call.new(callee, paren, arguments)
    end

    # Initialize parsing a call.
    # The call may be a function call, or a get expression (i.e. property access in a class instance).
    private def call : Expr
      expr = primary

      loop do
        if match?(TT::LEFT_PAREN)
          expr = finish_call(expr)
        elsif match?(TT::DOT)
          name = consume(TT::IDENTIFIER, "Expect property name after \".\".")
          expr = Expr::Get.new(expr, name)
        else
          break
        end
      end

      expr
    end

    # Parse a primary i.e. literal expression.
    # These include the following expressions:
    # `true`, `false`, `nil`, `self`, any number or string literal, identifiers i.e. variable names, or grouping expressions i.e. parentheses.
    # An exception is raised if none of those are found.
    private def primary : Expr
      return Expr::Literal.new(false) if match?(TT::FALSE)
      return Expr::Literal.new(true) if match?(TT::TRUE)
      return Expr::Literal.new(nil) if match?(TT::NIL)

      return Expr::Literal.new(previous.literal) if match?(TT::NUMBER, TT::STRING)

      return Expr::Self.new(previous) if match?(TT::SELF)

      return Expr::Variable.new(previous) if match?(TT::IDENTIFIER)

      if match?(TT::LEFT_PAREN)
        expr = expression
        consume(TT::RIGHT_PAREN, "Expect \")\" after expression.")
        return Expr::Grouping.new(expr)
      end

      raise error(peek, "Expect expression.")
    end

    # Check if any of any of `*types` match the next token's type.
    private def match?(*types : TT) : Bool
      types.each do |type|
        if check?(type)
          advance
          return true
        end
      end

      return false
    end

    # Check if a block needs to be implicitly ended at the next token.
    private def implicit_end_block_needed? : Bool
      !!(@implicit_end_block_at.find { |i| i == peek.type })
    end

    # Consume the next token if its type matches `type`.
    # Raises an exception with the provided message if the next token is not the specified one.
    private def consume(type : TT, message : String) : Token
      return advance if check?(type)

      raise error(peek, message)
    end

    # Cast a union type of (Stmt | Expr)? to a Stmt.
    # Raises an exception if it fails to do so due to a TypeCastError.
    private def as_stmt(stmt : (Stmt | Expr)?, message : String)
      begin
        return stmt.as(Stmt)
      rescue err : TypeCastError
        raise error(peek, message)
      end
    end

    # Checks if the next token's type is `type`.
    private def check?(type : TT) : Bool
      return false if at_end?
      return peek.type == type
    end

    # Checks a specific number of the next token types to see if they match the provided order.
    private def check?(*types : TT) : Bool
      return false if at_end?

      i = 0
      types.each do |type|
        if @tokens[current + i].type == type && !at_end?
          i += 1
          next
        else
          return false
        end
      end

      true
    end

    # Uses token lookaheads to check if the next tokens create an expression statement.
    # Useful for checking if the return statement is at the end of a block, for instance.
    private def expression_statement_next?
      is_call = check?(TT::IDENTIFIER, TT::LEFT_PAREN)
      is_assign = check?(TT::IDENTIFIER, TT::EQUAL)
      is_set_or_get = check?(TT::IDENTIFIER, TT::DOT)
      is_self_set_or_get = check?(TT::SELF, TT::DOT)

      val = is_call || is_assign || is_set_or_get || is_self_set_or_get
    end

    # Moves ahead in the token list.
    private def advance : Token
      @current += 1 unless at_end?
      previous
    end

    # Checks if the parser has reached the end of the token list.
    private def at_end? : Bool
      peek.type == TT::EOF
    end

    # Returns the next token, i.e. the token about to be parsed.
    private def peek : Token
      @tokens[current]
    end

    # Returns the token after the token about to be parsed.
    private def peek_next : Token
      @tokens[current + 1]
    end

    # Returns the token that was just parsed.
    private def previous : Token
      @tokens[current - 1]
    end

    # Prints an error message and returns a new ParseError.
    private def error(token : Token, message : String) : ParseError
      ParseError.new(token, message)
    end

    # Discards tokens until reaching EOF or until it finds one of some particular keywords.
    private def synchronize
      advance

      until at_end?
        return if previous.type == TT::END

        case peek.type
        when TT::CLASS, TT::FUN, TT::VAR, TT::FOR, TT::IF, TT::WHILE, TT::RETURN
          return
        end

        advance
      end
    end
  end
end
