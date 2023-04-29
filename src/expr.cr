require "./token"

module Kaze
  # All the types a visitor function can return.
  alias VG = (String | Float64 | Bool)?

  abstract class Expr
    module Visitor
      abstract def visit_assign_expr(expr : Assign) : VG
      abstract def visit_binary_expr(expr : Binary) : VG
      abstract def visit_grouping_expr(expr : Grouping) : VG
      abstract def visit_literal_expr(expr : Literal) : VG
      abstract def visit_unary_expr(expr : Unary) : VG
      abstract def visit_ternary_expr(expr : Ternary) : VG
      abstract def visit_variable_expr(expr : Variable) : VG
    end

    abstract def accept(visitor : Visitor)

    class Assign < Expr
      getter name
      getter value

      def initialize(@name : Token, @value : Expr)
      end

      def accept(visitor : Visitor)
        visitor.visit_assign_expr(self)
      end
    end

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

      def initialize(@value : VG)
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

    class Variable < Expr
      getter name

      def initialize(@name : Token)
      end

      def accept(visitor : Visitor)
        visitor.visit_variable_expr(self)
      end
    end
  end
end
