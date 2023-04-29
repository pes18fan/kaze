require "./token"

module Kaze
  abstract class Stmt
    module Visitor
      abstract def visit_expression_stmt(stmt : Expression) : VG
      abstract def visit_println_stmt(stmt : Println) : VG
      abstract def visit_var_stmt(stmt : Var) : VG
    end

    abstract def accept(visitor : Visitor)

    class Expression < Stmt
      getter expression

      def initialize(@expression : Expr)
      end

      def accept(visitor : Visitor)
        visitor.visit_expression_stmt(self)
      end
    end

    class Println < Stmt
      getter expression

      def initialize(@expression : Expr)
      end

      def accept(visitor : Visitor)
        visitor.visit_println_stmt(self)
      end
    end

    class Var < Stmt
      getter name
      getter initializer

      def initialize(@name : Token, @initializer : Expr?)
      end

      def accept(visitor : Visitor)
        visitor.visit_var_stmt(self)
      end
    end
  end
end