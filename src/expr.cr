require "./token"

module Kaze
  # Visitor generics.
  # These are all the types a visitor function can return.
  # In simple terms, all the types that a variable in Kaze can have.
  alias VG = (String | Float64 | Bool | Callable | Instance)?

  abstract class Expr
    module Visitor
      abstract def visit_assign_expr(expr : Assign) : VG
      abstract def visit_binary_expr(expr : Binary) : VG
      abstract def visit_call_expr(expr : Call) : VG
      abstract def visit_get_expr(expr : Get) : VG
      abstract def visit_grouping_expr(expr : Grouping) : VG
      abstract def visit_lambda_expr(expr : Lambda) : VG
      abstract def visit_literal_expr(expr : Literal) : VG
      abstract def visit_logical_expr(expr : Logical) : VG
      abstract def visit_self_expr(expr : Self) : VG
      abstract def visit_set_expr(expr : Set) : VG
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

    class Call < Expr
      getter callee
      getter paren
      getter arguments

      def initialize(@callee : Expr, @paren : Token, @arguments : Array(Expr))
      end

      def accept(visitor : Visitor)
        visitor.visit_call_expr(self)
      end
    end

    class Get < Expr
      getter object
      getter name

      def initialize(@object : Expr, @name : Token)
      end

      def accept(visitor : Visitor)
        visitor.visit_get_expr(self)
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

    class Lambda < Expr
      getter params
      getter body

      def initialize(@params : Array(Token), @body : Stmt)
      end

      def accept(visitor : Visitor)
        visitor.visit_lambda_expr(self)
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

    class Logical < Expr
      getter left
      getter operator
      getter right

      def initialize(@left : Expr, @operator : Token, @right : Expr)
      end

      def accept(visitor : Visitor)
        visitor.visit_logical_expr(self)
      end
    end

    class Self < Expr
      getter keyword

      def initialize(@keyword : Token)
      end

      def accept(visitor : Visitor)
        visitor.visit_self_expr(self)
      end
    end

    class Set < Expr
      getter object
      getter name
      getter value

      def initialize(@object : Expr, @name : Token, @value : Expr)
      end

      def accept(visitor : Visitor)
        visitor.visit_set_expr(self)
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
