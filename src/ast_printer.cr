require "./expr"

module Kaze
  # Pretty printer for an AST.
  class AstPrinter
    include Expr::Visitor

    def initialize
    end

    # Returns the final S-expression string.
    def stringify(expr : Expr) : String
      expr.accept(self)
    end

    # Parenthesizes a binary expression.
    def visit_binary_expr(expr : Expr::Binary) : String
      parenthesize(expr.operator.lexeme, expr.left, expr.right)
    end

    # Parenthesizes a expression grouped in parentheses.
    def visit_grouping_expr(expr : Expr::Grouping) : String
      parenthesize("group", expr.expression)
    end

    # Returns the literal value, or `nil` if it doesn't exist.
    def visit_literal_expr(expr : Expr::Literal) : String
      return "nil" if expr.value == nil
      return expr.value.to_s
    end

    # Parenthesizes a unary expression.
    def visit_unary_expr(expr : Expr::Unary) : String
      parenthesize(expr.operator.lexeme, expr.right)
    end

    # Parenthesizes a ternary expression.
    def visit_ternary_expr(expr : Expr::Ternary) : String
      parenthesize("?:", expr.condition, expr.left, expr.right)
    end

    # Parenthesizes a variable expression.
    def visit_variable_expr(expr : Expr::Variable) : String
      parenthesize("var", var.name)
    end

    # Parenthesizes an assignment.
    def visit_assign_expr(expr : Expr::Assign) : String
      parenthesize("=", expr.name, expr.value)
    end

    # Encapsulates an expression in parentheses as a part of the final S-expression.
    private def parenthesize(name : String, *exprs : Expr)
      String.build do |str|
        str << "("
        str << name

        exprs.each do |expr|
          str << " "
          str << expr.accept(self)
        end

        str << ")"
      end
    end
  end
end
