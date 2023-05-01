# kaze 風

**STILL VERY EARLY IN DEVELOPMENT**

An interpreted programming language. Based on everyone's favorite interpreted learning-language [Lox](https://www.craftinginterpreters.com). Focused on being easy to use and having intuitive syntax.

# quickstart

Pass in a Kaze source file to the interpreter:

```bash
kaze program.kaze
```

Or fire up a REPL by invoking the interpreter without any args:

```bash
kaze
```

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