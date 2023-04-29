require "./expr"
require "./environment"
require "./runtime_error"

module Kaze
  # Interpreter to compute expressions and statements.
  class Interpreter
    include Expr::Visitor
    include Stmt::Visitor

    private property environment = Environment.new

    def interpret(statements : Array(Stmt))
      begin
        statements.each do |statement|
          execute statement
        end
      rescue err : RuntimeError
        Kaze::Program.runtime_error(err)
      end
    end

    def visit_literal_expr(expr : Expr::Literal) : VG
      expr.value
    end

    def visit_grouping_expr(expr : Expr::Grouping) : VG
      evaluate(expr.expression)
    end

    def visit_unary_expr(expr : Expr::Unary) : VG
      right = evaluate(expr.right)

      case expr.operator.type
      when TT::BANG
        return !truthy?(right)
      when TT::MINUS
        check_number_operand(expr.operator, right)
        return (-(right.as(Float64)))
      end

      nil
    end

    def visit_binary_expr(expr : Expr::Binary) : VG
      left = evaluate(expr.left)
      right = evaluate(expr.right)

      case expr.operator.type
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
        if left.class == Float64 && right.class == Float64
          return left.as(Float64) + right.as(Float64)
        end

        if left.class == String && right.class == String
          return left.to_s + right.to_s
        end

        raise RuntimeError.new(expr.operator, "Operators must be two numbers or two strings.")
      when TT::SLASH
        check_number_operand(expr.operator, left, right)
        return left.as(Float64) / right.as(Float64) if right.as(Float64) != 0

        raise RuntimeError.new(expr.operator, "Cannot divide by zero.")
      when TT::STAR
        check_number_operand(expr.operator, left, right)
        return left.as(Float64) * right.as(Float64)
      end

      nil
    end

    def visit_ternary_expr(expr : Expr::Ternary) : VG
      condition = evaluate(expr.condition)
      left = evaluate(expr.left)
      right = evaluate(expr.right)

      return left if truthy?(condition)
      return right

      nil
    end
    
    def visit_variable_expr(expr : Expr::Variable) : VG
      environment.get(expr.name)
    end

    def visit_assign_expr(expr : Expr::Assign) : VG
      value = evaluate(expr.value)
      environment.assign(expr.name, value)
      value
    end

    private def check_number_operand(operator : Token, operand : VG)
      return if operand.class == Float64
      raise RuntimeError.new(operator, "Operand must be a number.")
    end

    private def check_number_operand(operator : Token, left : VG, right : VG)
      return if left.class == Float64 && right.class == Float64
      raise RuntimeError.new(operator, "Operands must be numbers.")
    end

    # `false` and `nil` are falsey, everything else if truthy
    private def truthy?(object : VG) : Bool
      return false if object == nil
      return !!object if object.class == Bool
      return true
    end

    private def equal?(a : VG, b : VG) : Bool
      return true if a == nil && b == nil
      return false if a == nil

      a == b
    end

    private def stringify(object : VG)
      return "nil" if object == nil
      
      if object.class == Float64
        text = object.to_s

        if text.ends_with?(".0")
          text = text[0...(text.size - 2)]
        end

        return text
      end

      return object.to_s
    end

    private def evaluate(expr : Expr)
      expr.accept(self)
    end

    private def execute(stmt : Stmt)
      stmt.accept(self)
    end

    def visit_expression_stmt(stmt : Stmt::Expression) : Nil
      evaluate(stmt.expression)
      nil
    end

    def visit_println_stmt(stmt : Stmt::Println) : Nil
      value = evaluate(stmt.expression)
      puts stringify(value)
      nil
    end

    def visit_var_stmt(stmt : Stmt::Var) : Nil
      value : VG = nil

      unless stmt.initializer.nil?
        value = evaluate(stmt.initializer.as(Expr))
      end

      environment.define(stmt.name.lexeme, value)
      nil
    end
  end
end