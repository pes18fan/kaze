require "./scanner"
require "./parser"
require "./resolver"
require "./interpreter"
require "./token"
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
      begin
        data = File.read(path)
      rescue err : File::NotFoundError
        STDERR.puts "File #{path} not found."
        exit 66
      end
      run(data, false)
      exit 65 if @@had_error
      exit 70 if @@had_runtime_error
    end

    # Fires up a REPL.
    def run_prompt
      puts "Kaze interpreter."
      puts "Enter \".exit\" to exit."
      i = 1
      loop do
        prompt = ""

        print "kaze:#{i}> "
        line = gets
        break if line.nil?

        if line.as(String)[-1] == '\\'
          line = line.as(String)[0..-2] + '\n'
          loop do
            i += 1

            print "kaze:#{i}| "

            line_or_nil = gets
            break if line_or_nil == Nil

            line += line_or_nil.as(String)
            break if line.as(String)[-1] != '\\'

            line = line[0..-2]
            line = line + '\n'
          end
        end

        break if line == ".exit"

        prompt = line.to_s
        run(prompt, true)
        @@had_error = false
        i += 1
      end
    end

    # Runs `source`.
    # The source is first sent to the scanner which returns tokens out of it.
    # The tokens are then parsed by the parser.
    # The resolver then takes the parsed statements and does semantic analysis.
    # Finally, the statements are sent to the interpreter to be executed.
    # The function may return after each of these steps if it has an error.
    private def run(source : String, repl : Bool)
      scanner = Scanner.new(source)
      tokens = scanner.scan_tokens

      return if @@had_error

      parser = Parser.new(tokens.as(Array(Token)), repl)
      statements = parser.parse

      return if @@had_error

      resolver = Resolver.new(@@interpreter)
      resolver.resolve(statements)

      return if @@had_error

      @@interpreter.interpret(statements)
    end

    # Reports an error with a token.
    def self.error(token : Token, message : String)
      if token.type == TT::EOF
        report(token.line, "at end", message, token.column)
      else
        report(token.line, "at \"" + token.lexeme + "\"", message, token.column)
      end
    end

    # Reports an error in a particular line.
    def self.error(line : Int32, message : String, column : Int32? = nil)
      report(line, "", message, column)
    end

    # Reports a runtime error.
    def self.runtime_error(error : RuntimeError)
      STDERR.puts "[line #{error.token.line}] Error: #{error.message}"
      @@had_runtime_error = true
    end

    # Prints an error message.
    private def self.report(line : Int32, where : String, message : String, column : Int32? = nil)
      STDERR.puts "[line #{line}#{column.nil? ? "" : " : #{column}"}] Error#{where.empty? ? "" : " #{where}"}: #{message}"
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
