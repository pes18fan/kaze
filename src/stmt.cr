require "./token"

module Kaze
  abstract class Stmt
    module Visitor
      abstract def visit_block_stmt(stmt : Block) : VG
      abstract def visit_expression_stmt(stmt : Expression) : VG
      abstract def visit_if_stmt(stmt : If) : VG
      abstract def visit_println_stmt(stmt : Println) : VG
      abstract def visit_var_stmt(stmt : Var) : VG
      abstract def visit_while_stmt(stmt : While) : VG
    end

    abstract def accept(visitor : Visitor)

    class Block < Stmt
      getter statements

      def initialize(@statements : Array(Stmt))
      end

      def accept(visitor : Visitor)
        visitor.visit_block_stmt(self)
      end
    end

    class Expression < Stmt
      getter expression

      def initialize(@expression : Expr)
      end

      def accept(visitor : Visitor)
        visitor.visit_expression_stmt(self)
      end
    end

    class If < Stmt
      getter condition
      getter then_branch
      getter else_branch

      def initialize(@condition : Expr, @then_branch : Stmt, @else_branch : Stmt?)
      end

      def accept(visitor : Visitor)
        visitor.visit_if_stmt(self)
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

    class While < Stmt
      getter condition
      getter body

      def initialize(@condition : Expr, @body : Stmt)
      end

      def accept(visitor : Visitor)
        visitor.visit_while_stmt(self)
      end
    end
  end
end
