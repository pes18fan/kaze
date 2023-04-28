if (ARGV.size != 1)
  STDERR.puts "Usage: generate_ast <output directory>"
  exit 64
end

output_dir = ARGV[0]

define_ast(output_dir, "expr", [
  "Binary    $     left : Expr, operator : Token, right : Expr",
  "Grouping  $     expression : Expr",
  "Literal   $     value : VisitorGenerics",
  "Unary     $     operator : Token, right : Expr",
  "Ternary   $     condition : Expr, left : Expr, right : Expr"
], "(String | Float64 | Bool)?")

# Define the base AST class.
private def define_ast(output_dir : String, file_name : String, types : Array(String), visitor_generics : String)
  path = output_dir + "/" + file_name + ".cr"
  base_name = file_name.capitalize

  File.open(path, "w") do |file|
    file.puts "require \"./token\""
    file.puts

    file.puts "module Kaze"
    file.puts "  # Extendible abstract class for expressions."
    file.puts "  abstract class #{base_name}"

    file.puts "    # All the types a visitor function can return."
    file.puts "    alias VisitorGenerics = #{visitor_generics}"
    file.puts
    
    define_visitor(file, base_name, types)
    file.puts
    
    file.puts "    abstract def accept(visitor : Visitor)"
    file.puts

    types.each do |type|
      class_name = type.split("$")[0].strip
      fields = type.split("$")[1].strip
      define_type(file, base_name, class_name, fields)
      file.puts
    end

    file.puts "  end" # abstract class closed
    file.puts "end"
  end
end

# Define types for the AST.
private def define_type(file : IO, base_name : String, class_name : String, field_list : String)
  file.puts "    class #{class_name} < #{base_name}"

  # Store parameters in fields.
  fields = field_list.split(", ")
  fields.each do |field|
    name = field.split(" : ")[0].strip
    file.puts "      getter #{name}"
  end

  file.puts

  # Constructor.
  file.print "      def initialize("
  fields.each do |field|
    if field == fields[fields.size - 1]
      file.print "@#{field}"
      break
    end

    file.print "@#{field}, "
  end
  
  file.print ")"
  file.puts

  file.puts "      end"

  file.puts
  file.puts "      def accept(visitor : Visitor)"
  file.puts "        visitor.visit_#{class_name.downcase}_#{base_name.downcase}(self)"
  file.puts "      end"

  file.puts "    end"
end

# Generates visitor interfaces.
private def define_visitor(file : IO, base_name : String, types : Array(String))
  file.puts "    module Visitor"

  types.each do |type|
    type_name = type.split("$")[0].strip
    file.puts "      abstract def visit_#{type_name.downcase}_#{base_name.downcase}(#{base_name.downcase} : #{type_name}) : VisitorGenerics"
  end

  file.puts "    end"
end
