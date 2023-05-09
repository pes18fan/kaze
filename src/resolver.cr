require "./expr"
require "./stmt"
require "./interpreter"
require "./util"

module Kaze
  # The resolver.
  # Resolves variable locations so that the interpreter can know exactly where a variable is, and what it is.
  # Also checks for semantic errors like self-assignment in variable definitions and `return`s outside a function.
  class Resolver
    include Expr::Visitor
    include Stmt::Visitor

    private property interpreter : Interpreter

    private enum FunctionType
      NONE
      FUNCTION
      INITIALIZER
      LAMBDA
      METHOD
    end

    private enum ClassType
      NONE
      CLASS
    end

    def initialize(@interpreter : Interpreter)
      # A stack, represented as an array.
      @scopes = Util::Stack(Hash(String, Bool)).new

      @current_function = FunctionType::NONE
      @current_class = ClassType::NONE
    end

    def resolve(statements : Array(Stmt))
      statements.each do |statement|
        resolve(statement)
      end
    end

    def resolve(statement : (Stmt | Expr)?)
      if statement.is_a?(Stmt)
        resolve(statement.as(Stmt))
      else
        resolve(statement.as(Expr)) unless statement.nil?
      end
    end

    def visit_block_stmt(stmt : Stmt::Block) : Nil
      begin_scope
      resolve(stmt.statements)
      end_scope
      nil
    end

    def visit_class_stmt(stmt : Stmt::Class) : Nil
      enclosing_class = @current_class
      @current_class = ClassType::CLASS

      declare(stmt.name)
      define(stmt.name)

      begin_scope
      @scopes.peek["self"] = true

      stmt.methods.each do |method|
        declaration = FunctionType::METHOD

        if method.name.as(Token).lexeme == "init"
          declaration = FunctionType::INITIALIZER
        end

        resolve_function(method, declaration)
      end

      end_scope

      @current_class = enclosing_class
      nil
    end

    def visit_expression_stmt(stmt : Stmt::Expression) : Nil
      resolve(stmt.expression)
      nil
    end

    def visit_if_stmt(stmt : Stmt::If) : Nil
      resolve(stmt.condition)
      resolve(stmt.then_branch)
      resolve(stmt.else_branch) unless stmt.else_branch.nil?
    end

    def visit_return_stmt(stmt : Stmt::Return) : Nil
      if @current_function == FunctionType::NONE
        Program.error(stmt.keyword, "Can't return from top-level code.")
      end

      unless stmt.value.nil?
        if @current_function == FunctionType::INITIALIZER
          Program.error(stmt.keyword, "Can't return a value from an initializer.")
        end

        resolve(stmt.value)
      end
      
      nil
    end

    def visit_while_stmt(stmt : Stmt::While) : Nil
      resolve(stmt.condition)
      resolve(stmt.body)
      nil
    end

    def visit_function_stmt(stmt : Stmt::Function) : Nil
      declare(stmt.name.as(Token))
      define(stmt.name.as(Token))

      resolve_function(stmt, FunctionType::FUNCTION)
      nil
    end

    # The variable isn't resolved if it is named `_`.
    # That is due to the `_` variables not creating any variable definition.
    # This is useful to evaluate expressions since Kaze doesn't support expression statements in most cases.
    def visit_var_stmt(stmt : Stmt::Var) : Nil
      declare(stmt.name) unless stmt.name.lexeme == "_"
      resolve(stmt.initializer) unless stmt.initializer.nil?
      define(stmt.name) unless stmt.name.lexeme == "_"
      nil
    end

    def visit_lambda_expr(expr : Expr::Lambda) : Nil
      resolve_lambda(expr)
      nil
    end

    def visit_assign_expr(expr : Expr::Assign) : Nil
      resolve(expr.value)
      resolve_local(expr, expr.name)
      nil
    end

    def visit_ternary_expr(expr : Expr::Ternary) : Nil
      resolve(expr.condition)
      resolve(expr.left)
      resolve(expr.right)
      nil
    end

    def visit_binary_expr(expr : Expr::Binary) : Nil
      resolve(expr.left)
      resolve(expr.right)
      nil
    end

    def visit_call_expr(expr : Expr::Call) : Nil
      resolve(expr.callee)

      expr.arguments.each do |argument|
        resolve(argument)
      end

      nil
    end

    def visit_get_expr(expr : Expr::Get) : Nil
      resolve(expr.object)
      nil
    end

    def visit_set_expr(expr : Expr::Set) : Nil
      resolve(expr.value)
      resolve(expr.object)
      nil
    end

    def visit_self_expr(expr : Expr::Self) : Nil
      if @current_class == ClassType::NONE
        Program.error(expr.keyword, "Can't use \"self\" outside of a class.")
      end

      resolve_local(expr, expr.keyword)
      nil
    end

    def visit_grouping_expr(expr : Expr::Grouping) : Nil
      resolve(expr.expression)
      nil
    end

    def visit_literal_expr(expr : Expr::Literal) : Nil
      nil
    end

    def visit_logical_expr(expr : Expr::Logical) : Nil
      resolve(expr.left)
      resolve(expr.right)
      nil
    end

    def visit_unary_expr(expr : Expr::Unary) : Nil
      resolve(expr.right)
      nil
    end

    def visit_variable_expr(expr : Expr::Variable) : Nil
      # Must check if the key exists before trying to see if it has a `false` value.
      # Not doing that throws a KeyError.
      if !@scopes.empty? && @scopes.peek.has_key?(expr.name.lexeme)
        Program.error(expr.name, "Can't read local variable in its own initializer.") if @scopes.peek[expr.name.lexeme] == false
      end

      resolve_local(expr, expr.name)
      nil
    end

    def resolve(stmt : Stmt)
      stmt.accept(self)
    end

    def resolve(expr : Expr)
      expr.accept(self)
    end

    private def begin_scope
      @scopes.push(Hash(String, Bool).new)
    end

    private def end_scope
      @scopes.pop
    end

    private def declare(name : Token)
      return if @scopes.empty?

      scope = @scopes.peek
      if scope.has_key?(name.lexeme)
        Program.error(name, "Variable with the same name already exists in this scope.")
      end

      scope[name.lexeme] = false
    end

    private def define(name : Token)
      return if @scopes.empty?

      @scopes.peek[name.lexeme] = true
    end

    private def resolve_function(function : Stmt::Function, type : FunctionType)
      enclosing_function = @current_function
      @current_function = type

      begin_scope

      function.params.each do |param|
        declare(param)
        define(param)
      end

      resolve(function.body)
      end_scope

      @current_function = enclosing_function
    end

    private def resolve_lambda(lambda : Expr::Lambda)
      enclosing_function = @current_function
      @current_function = FunctionType::LAMBDA

      begin_scope

      lambda.params.each do |param|
        declare(param)
        define(param)
      end

      resolve(lambda.body)
      end_scope

      @current_function = enclosing_function
    end

    private def resolve_local(expr : Expr, name : Token)
      i = @scopes.size - 1

      while i >= 0
        if @scopes[i].has_key?(name.lexeme)
          @interpreter.resolve(expr, @scopes.size - 1 - i)
          return
        end

        i -= 1
      end
    end
  end
end
