require "./expr"
require "./stmt"
require "./environment"
require "./runtime_error"
require "./callable"
require "./yawaraka"
require "./function"
require "./kaze_class"
require "./util"
require "./return"

module Kaze
  # Interpreter to compute expressions and statements.
  class Interpreter
    include Expr::Visitor
    include Stmt::Visitor

    # The global environment.
    property globals = Environment.new

    # Constructor function for the interpreter.
    # Assigns @globals as the current environment.
    # Also defines the standard library functions in the global environment.
    def initialize
      @environment = @globals
      @locals = Hash(Expr, Int32).new

      # Library function definitions.
      @globals.define("print", Yawaraka::Print.new)
      @globals.define("clock", Yawaraka::Clock.new)
      @globals.define("scanln", Yawaraka::Scanln.new)
    end

    # Interprets a source file.
    def interpret(statements : Array(Stmt))
      begin
        statements.each do |statement|
          execute statement
        end
      rescue err : RuntimeError
        Program.runtime_error(err)
      end
    end

    # Interprets a line in the REPL.
    # Can execute statements and also evaluate expressions.
    def interpret(statement : (Stmt | Expr)?)
      begin
        if statement.is_a?(Stmt)
          return_val = execute statement.as(Stmt)
          puts return_stringify(return_val)
        else
          return_val = evaluate statement.as(Expr) unless statement.is_a?(Nil)
          puts return_stringify(return_val)
        end
      rescue err : RuntimeError
        Program.runtime_error(err)
      end
    end

    # Evaluates a literal expression.
    def visit_literal_expr(expr : Expr::Literal) : VG
      expr.value
    end

    # Evaluates a logical AND or OR expression.
    def visit_logical_expr(expr : Expr::Logical) : VG
      left = evaluate expr.left

      if expr.operator.type == TT::OR
        return left if truthy?(left)
      else
        return left unless truthy?(left)
      end

      evaluate expr.right
    end

    # Evaluates a grouping (parenthesized) expression.
    def visit_grouping_expr(expr : Expr::Grouping) : VG
      evaluate(expr.expression)
    end

    # Evaluates a unary expression.
    def visit_unary_expr(expr : Expr::Unary) : VG
      right = evaluate(expr.right)

      case expr.operator.type
      when TT::NOT
        return !truthy?(right)
      when TT::MINUS
        check_number_operand(expr.operator, right)
        return (-(right.as(Float64)))
      end

      nil
    end

    # Evaluates a binary expression.
    def visit_binary_expr(expr : Expr::Binary) : VG
      left = evaluate(expr.left)
      right = evaluate(expr.right)

      case expr.operator.type
      # Equality operators.
      when TT::BANG_EQUAL
        return !equal?(left, right)
      when TT::EQUAL_EQUAL
        return equal?(left, right)
        # Comparison operators.
      when TT::GREATER
        check_number_operand(expr.operator, left, right)
        return left.as(Float64) > right.as(Float64)
      when TT::GREATER_EQUAL
        check_number_operand(expr.operator, left, right)
        return left.as(Float64) >= right.as(Float64)
      when TT::LESS
        check_number_operand(expr.operator, left, right)
        return left.as(Float64) < right.as(Float64)
      when TT::LESS_EQUAL
        check_number_operand(expr.operator, left, right)
        return left.as(Float64) <= right.as(Float64)
        # Arithmetic operators.
      when TT::MINUS
        check_number_operand(expr.operator, left, right)
        return left.as(Float64) - right.as(Float64)
      when TT::PLUS
        if left.is_a?(Float64) && right.is_a?(Float64)
          return left.as(Float64) + right.as(Float64)
        end

        return Util.stringify(left) + Util.stringify(right)
      when TT::SLASH
        check_number_operand(expr.operator, left, right)
        return left.as(Float64) / right.as(Float64) if right.as(Float64) != 0

        raise RuntimeError.new(expr.operator, "Cannot divide by zero.")
      when TT::PERCENT
        check_number_operand(expr.operator, left, right)
        return left.as(Float64) % right.as(Float64) if right.as(Float64) != 0

        raise RuntimeError.new(expr.operator, "Cannot divide by zero.")
      when TT::STAR
        check_number_operand(expr.operator, left, right)
        return left.as(Float64) * right.as(Float64)
      end

      nil
    end

    # Evaluates a function call.
    def visit_call_expr(expr : Expr::Call) : VG
      callee = evaluate expr.callee

      arguments = Array(VG).new

      expr.arguments.each do |arg|
        arguments << evaluate arg
      end

      unless callee.is_a?(Callable)
        raise RuntimeError.new(expr.paren, "Can only call functions and classes.")
      end

      function = callee.as(Callable)

      if arguments.size != function.arity
        raise RuntimeError.new(expr.paren, "Expected #{function.arity} arguments but got #{arguments.size}.")
      end

      function.call(self, arguments)
    end

    # Evaluates a get expression.
    # Raises an exception if the expression's object is not a class instance.
    def visit_get_expr(expr : Expr::Get) : VG
      object = evaluate(expr.object)

      if object.is_a?(Instance)
        return object.as(Instance).get(expr.name)
      end

      raise RuntimeError.new(expr.name, "Only instances have properties.")
    end

    # Evaluates a set expression.
    def visit_set_expr(expr : Expr::Set) : VG
      object = evaluate(expr.object)

      unless object.is_a?(Instance)
        raise RuntimeError.new(expr.name, "Only instances have fields.")
      end

      value = evaluate(expr.value)
      object.as(Instance).set(expr.name, value)
      value
    end

    # Evaluates `self`.
    def visit_self_expr(expr : Expr::Self) : VG
      look_up_variable(expr.keyword, expr)
    end

    # Evaluates a ternary i.e. conditional expression.
    # The expression on the right only evaluates if the one on the left is false.
    def visit_ternary_expr(expr : Expr::Ternary) : VG
      condition = evaluate(expr.condition)
      left = evaluate(expr.left)

      return left if truthy?(condition)

      right = evaluate(expr.right)

      return right

      nil
    end

    # Evaluates a variable expression i.e. a variable being used as an expression.
    def visit_variable_expr(expr : Expr::Variable) : VG
      look_up_variable(expr.name, expr)
    end

    private def look_up_variable(name : Token, expr : Expr) : VG
      distance = @locals[expr]?

      unless distance.nil?
        return @environment.get_at(distance, name.lexeme)
      else
        return @globals.get(name)
      end
    end

    # Evaluates a anonymous lambda function.
    # This simply creates a new function without a name.
    def visit_lambda_expr(expr : Expr::Lambda) : VG
      Function.new(Stmt::Function.new(nil, expr.params, [expr.body]), @environment, false)
    end

    # Evaluates an assignment expression.
    def visit_assign_expr(expr : Expr::Assign) : VG
      value = evaluate(expr.value)

      distance = @locals[expr]?

      unless distance.nil?
        @environment.assign_at(distance, expr.name, value)
      else
        @globals.assign(expr.name, value)
      end

      value
    end

    # Checks if the operand is a float.
    private def check_number_operand(operator : Token, operand : VG)
      return if operand.is_a?(Float64)
      raise RuntimeError.new(operator, "Operand must be a number.")
    end

    # Checks if the operands are floats.
    private def check_number_operand(operator : Token, left : VG, right : VG)
      return if left.is_a?(Float64) && right.is_a?(Float64)
      raise RuntimeError.new(operator, "Operands must be numbers.")
    end

    # Checks if an expression is truthy or falsey.
    # `false` and `nil` are falsey, everything else is truthy.
    private def truthy?(object : VG) : Bool
      return false if object == nil
      return !!object if object.class == Bool
      return true
    end

    # Checks if two expressions are equal.
    private def equal?(a : VG, b : VG) : Bool
      return true if a == nil && b == nil
      return false if a == nil

      a == b
    end



    # Stringifies an expression value, but also prepends a `=>`.
    # Used in the REPL to show the return value of expressions.
    private def return_stringify(object : VG)
      "=> #{Util.stringify(object)}"
    end

    # Evaluates an expression.
    private def evaluate(expr : Expr)
      expr.accept(self)
    end

    # Executes a statement.
    private def execute(stmt : Stmt)
      stmt.accept(self)
    end

    # Resloves an expression.
    def resolve(expr : Expr, depth : Int32)
      @locals[expr] = depth
    end

    # Creates a new environment for a block, and executes the block's statement array.
    def execute_block(statements : Array(Stmt), environment : Environment)
      previous = @environment

      begin
        @environment = environment

        statements.each do |statement|
          execute statement
        end
      ensure
        @environment = previous
      end
    end

    # Executes a statement block.
    def visit_block_stmt(stmt : Stmt::Block) : Nil
      execute_block(stmt.statements, Environment.new(@environment))
      nil
    end

    # Interprets a class.
    def visit_class_stmt(stmt : Stmt::Class) : Nil
      @environment.define(stmt.name.lexeme, nil)

      methods = Hash(String, Function).new

      stmt.methods.each do |method|
        function = Function.new(method, @environment, method.name.as(Token).lexeme == "init")
        methods[method.name.as(Token).lexeme] = function
      end

      klass = KazeClass.new(stmt.name.lexeme, methods)
      @environment.assign(stmt.name, klass)
      nil
    end

    # Executes an expression statement.
    def visit_expression_stmt(stmt : Stmt::Expression) : Nil
      evaluate(stmt.expression)
      nil
    end

    # Executes a function statement i.e. a function definition.
    def visit_function_stmt(stmt : Stmt::Function) : Nil
      function = Function.new(stmt, @environment, false)
      @environment.define(stmt.name.as(Token).lexeme, function)
      nil
    end

    # Executes an if statement.
    def visit_if_stmt(stmt : Stmt::If) : Nil
      if truthy?(evaluate stmt.condition)
        execute stmt.then_branch
      elsif stmt.else_branch != nil
        execute stmt.else_branch.as(Stmt)
      end

      nil
    end

    # Executes a return statement.
    def visit_return_stmt(stmt : Stmt::Return) : Nil
      value = nil
      value = evaluate stmt.value.as(Expr) if stmt.value != nil

      # raise an exception to get the return value back to the top of the stack
      raise Return.new(value)
    end

    # Executes a variable declaration.
    def visit_var_stmt(stmt : Stmt::Var) : Nil
      value : VG = nil

      unless stmt.initializer.nil?
        value = evaluate(stmt.initializer.as(Expr))
      end

      @environment.define(stmt.name.lexeme, value)
      nil
    end

    # Executes a while statement.
    def visit_while_stmt(stmt : Stmt::While) : Nil
      while truthy?(evaluate stmt.condition)
        execute stmt.body
      end
    end
  end
end
