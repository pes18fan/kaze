# kaze 風

A basic tree-walk interpreter for Kaze, a simple interpreted programming language. Based on everyone's favorite interpreted learning-language [Lox](https://www.craftinginterpreters.com). Focused on being easy to use and having intuitive syntax.

I created this to learn some basic things about programming language development. Kaze will recieve a much faster and more optimized bytecode-compiling interpreter in the future.

# quickstart

Pass in a Kaze source file to the interpreter:

```bash
kaze program.kaze
```

Or fire up a REPL by invoking the interpreter without any args:

```bash
kaze
```

## vscode extension

This repo includes a VSCode extension that provides syntax highlighting for the language! To use it, simply move the folder into your `.vscode/extensions/` directory in your home folder, which is `~` in Linux and `C:\Users\<username>` in Windows.

## examples

### hello, world

```kaze
print("hello, world!\n")
```

### square root

```kaze
fun sqrt <- x begin
    var z = 1

    for var i = 0; i <= 10; i = i + 1 do
        z = z - ( ( z * z - x ) / (2 * z) )

    return z
end

print(sqrt(36)) //=> 6
```

See more examples in `/examples/`.

# building

You need the following to build Kaze:

- [`crystal`](https://crystal-lang.org/install): The language in which the interpreter is written.
- [`just`](https://www.github.com/casey/just): A command runner with syntax similar to `make`, used as the build tool. Note that on Windows, you'll need a `sh` like Git Bash to use it.

Run the following to build a development build for Kaze!

```bash
git clone https://www.github.com/pes18fan/kaze.git
cd kaze
just
```

The build will be produced as `bin/debug/kaze`. To produce a release build as `bin/release/kaze`, run:

```bash
just r
```