require "./scanner"
require "./parser"
require "./interpreter"
require "./token"
require "./ast_printer"
require "./runtime_error"

module Kaze
  # Class for the main process.
  class Program
    @@interpreter = Interpreter.new
    @@had_error = false
    @@had_runtime_error = false
    @@loc = 1

    def initialize
      if ARGV.size > 1
        puts "Usage: kaze [script]"
        exit 64
      elsif ARGV.size == 1
        run_file(ARGV[0])
      else
        run_prompt
      end
    end

    # Interprets a file.
    def run_file(path : String)
      data = File.read(path)
      run(data, false)
      exit 65 if @@had_error
      exit 70 if @@had_runtime_error
    end

    # Fires up a REPL.
    def run_prompt
      puts "Enter \".exit\" to exit"
      loop do
        print "> "
        line = gets(chomp: true)
        break if line.nil? || line == ".exit"
        run(line.to_s, true)
        @@had_error = false
      end
    end

    # Sends `source` to the scanner to be scanned.
    private def run(source : String, repl : Bool)
      scanner = Scanner.new(source)
      tokens = scanner.scan_tokens

      return if @@had_error

      parser = Parser.new(tokens.as(Array(Token)), repl)
      statements = parser.parse

      return if @@had_error

      @@interpreter.interpret(statements)
    end

    # Reports an error with a token.
    def self.error(token : Token, message : String)
      if token.type == TT::EOF
        report(token.line, "at end", message)
      else
        report(token.line, "at \"" + token.lexeme + "\"", message)
      end
    end

    # Reports an error in a particular line.
    def self.error(line : Int32, message : String)
      report(line, "", message)
    end

    def self.runtime_error(error : RuntimeError)
      STDERR.puts "[line #{error.token.line}] Error: #{error.message}"
      @@had_runtime_error = true
    end

    # Prints an error message.
    private def self.report(line : Int32, where : String, message : String)
      STDERR.puts "[line #{line}] Error#{where.empty? ? "" : " #{where}"}: #{message}"
      @@had_error = true
    end

    def self.had_error
      @@had_error
    end

    def self.loc
      @@loc
    end

    def self.loc=(other : Int32)
      @@loc = other
    end
  end
end

Kaze::Program.new
