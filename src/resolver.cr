require "./expr"
require "./stmt"
require "./interpreter"

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
    end

    def initialize(@interpreter : Interpreter)
      @scopes = Array(Hash(String, Bool)).new
      @current_function = FunctionType::NONE
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

    def visit_expression_stmt(stmt : Stmt::Expression) : Nil
      resolve(stmt.expression)
      nil
    end

    def visit_if_stmt(stmt : Stmt::If) : Nil
      resolve(stmt.condition)
      resolve(stmt.then_branch)
      resolve(stmt.else_branch) unless stmt.else_branch.nil?
    end

    def visit_println_stmt(stmt : Stmt::Println) : Nil
      resolve(stmt.expression)
      nil
    end

    def visit_return_stmt(stmt : Stmt::Return) : Nil
      if @current_function == FunctionType::NONE
        Program.error(stmt.keyword, "Can't return from top-level code.")
      end

      resolve(stmt.value) unless stmt.value.nil?
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

    def visit_var_stmt(stmt : Stmt::Var) : Nil
      declare(stmt.name)
      resolve(stmt.initializer) unless stmt.initializer.nil?
      define(stmt.name)
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
      if !@scopes.empty? && @scopes.last[expr.name.lexeme] == false
        Program.error(expr.name, "Can't read local variable in its own initializer.")
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
      @scopes.delete_at(0)
    end

    private def declare(name : Token)
      return if @scopes.empty?

      scope = @scopes.last
      if scope.has_key?(name.lexeme)
        Program.error(name, "Variable with the same name already exists in this scope.")
      end

      scope[name.lexeme] = false
    end

    private def define(name : Token)
      return if @scopes.empty?

      @scopes.last[name.lexeme] = true
    end

    private def resolve_local(expr : Expr, name : Token)
      i = 0

      while i <= @scopes.size - 1
        if @scopes[i].has_key?(name.lexeme)
          @interpreter.resolve(expr, i)
        end

        i += 1
      end
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
      begin_scope

      lambda.params.each do |param|
        declare(param)
        define(param)
      end

      resolve(lambda.body)
      end_scope
    end
  end
end
