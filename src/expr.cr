require "./token"

module Kaze
  abstract class Expr
    # All the types a visitor function can return.
    alias VisitorGenerics = (String | Float64 | Bool)?

    module Visitor
      abstract def visit_binary_expr(expr : Binary) : VisitorGenerics
      abstract def visit_grouping_expr(expr : Grouping) : VisitorGenerics
      abstract def visit_literal_expr(expr : Literal) : VisitorGenerics
      abstract def visit_unary_expr(expr : Unary) : VisitorGenerics
      abstract def visit_ternary_expr(expr : Ternary) : VisitorGenerics
    end

    abstract def accept(visitor : Visitor)

    class Binary < Expr
      getter left
      getter operator
      getter right

      def initialize(@left : Expr, @operator : Token, @right : Expr)
      end

      def accept(visitor : Visitor)
        visitor.visit_binary_expr(self)
      end
    end

    class Grouping < Expr
      getter expression

      def initialize(@expression : Expr)
      end

      def accept(visitor : Visitor)
        visitor.visit_grouping_expr(self)
      end
    end

    class Literal < Expr
      getter value

      def initialize(@value : VisitorGenerics)
      end

      def accept(visitor : Visitor)
        visitor.visit_literal_expr(self)
      end
    end

    class Unary < Expr
      getter operator
      getter right

      def initialize(@operator : Token, @right : Expr)
      end

      def accept(visitor : Visitor)
        visitor.visit_unary_expr(self)
      end
    end

    class Ternary < Expr
      getter condition
      getter left
      getter right

      def initialize(@condition : Expr, @left : Expr, @right : Expr)
      end

      def accept(visitor : Visitor)
        visitor.visit_ternary_expr(self)
      end
    end
  end
end
