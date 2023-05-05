ast_generator_path := "scripts/generate_ast.cr"
exec_name := "kaze" 
exec_target := "bin/debug/kaze"
exec_release := "bin/release/kaze"

alias r := release
alias a := ast

# Build the interpreter.
debug:
    @mkdir -p bin/debug/ || true
    @echo "Compiling..."
    @shards build generate_ast --progress
    @crystal run {{ ast_generator_path }} -- src/
    @shards build {{ exec_name }} --progress
    @mv bin/{{ exec_name }} bin/debug
    @echo "Compiled successfully."

# Build the interpreter in release mode.
release:
    @mkdir -p bin/release/ || true
    @echo "Compiling in release mode..."
    @shards build generate_ast --progress
    @crystal run {{ ast_generator_path }} -- src/
    @shards build {{ exec_name }} --progress --release --no-debug
    @mv bin/{{ exec_name }} bin/release
    @echo "Compiled successfully."

# Generate the abstract syntax trees.
ast:
    @echo "Generating ASTs..."
    @shards build generate_ast --progress
    @crystal run {{ ast_generator_path }} -- src/
    @echo "ASTs generated successfully."
