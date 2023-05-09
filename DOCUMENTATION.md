Welcome to kaze! Kaze is a super simple interpreted language designed as a small toy project of mine. It is mainly influenced by Ruby, Lua and Lox (on which the interpreter itself is based!). Enjoy your stay!

Please note that this is experimental software, and things have a high chance of breaking.

Get started with a hello world:

```kaze
print("hello, world!\n")
```

# Syntax

A program in Kaze consists of statements. Statements don't need a terminator (like a newline or semicolon).

## variables

Variables are dynamically declared using the `var` keyword, and may or may not be assigned to at the time of declaration:

```kaze
var a = 1
var b
```

If you try to use an unitialized variable, the interpreter will throw an error!

```kaze
var undec

print(undec) // Variable "undec" not assigned to a value.
```

Variable names support any number of alphanumeric characters, underscores, question marks and exclamation marks. However, they must begin with a letter.

```kaze
var epic! // valid
var a?b // valid
var 2a // invalid
```

## blocks

```kaze
begin
    [stmt(s)]
end
```

A block evaluates `[stmt(s)]` sequentially. Variables inside a block are scoped to it and cannot be used outside it.

## if..else

```kaze
if [expr] do [then_stmt] else [else_stmt]
```

Or, for blocks,

```kaze
if [expr] begin
    [then_stmt(s)]
else
    [else_stmt(s)]
end
```

`[then_stmt(s)]` is evaluated if `[expr]` is truthy, else `[else_stmt(s)]` is evaluated.

## Loops

Kaze supports `while` and `for` loops.

### while

```kaze
while [expr] do [stmt]
```

In block syntax:

```kaze
while [expr] begin
    [stmt(s)]
end
```

`[stmt(s)]` is evaluated as long as `[expr]` is truthy.

### for

```kaze
for [initializer];[condition];[increment] do [stmt]
```

In block syntax:

```kaze
for [initializer];[condition];[increment] begin
    [stmt(s)]
end
```

`[stmt(s)]` is evaluated as long as the `[condition]` expression is truthy, with the `[initializer]` statement (which may either be a variable declaration or any expression) running once before the entire loop and the `[increment]` expression running after every iteration.

Note that any or all of these clauses can be omitted, but the semicolons can't.

# Functions

```kaze
fun [name] <- [params] begin
    [stmt(s)]
end
```

Without any parameters:

```kaze
fun [name] begin
    [stmt(s)]
end
```

You can call a function by `name()`.

For example:

```kaze
fun hello_there begin
    print("hello!\n")
end

hello_there() //=> "hello!"
```

Or with params:

```kaze
fun greet <- greeting begin
    print(greeting)
end

greet("hey!") //=> "hey!"
```

## lambda

Anonymous lambda functions, just like in Python, can be created with the `lambda` keyword. They work similarlty as they would in Python, as in the fact that their body must only be one expression, which is what they return. Lambdas may take zero or more arguments.

```kaze
var a = lambda x: x * 2

a(2) //=> 4
```

# Classes

Kaze supports basic OOP patterns with classes.

```kaze
class Greeter begin
    greet begin
        print("hello, friend!")
    end
end

var greeter = Greeter()
greeter.greet() // hello, friend!
```

You can assign custom properties to classes via the `.` syntax. Such properties can be accessed using the special variable `self`, which represents the instance, similar to `this` in languages like Java.

```kaze
class Greeter begin
    greet begin
        print("hello, " + self.name + "!")
    end
end

var greeter = Greeter()
greeter.name = "p18f"
greeter.greet() // hello, p18f!
```

Class constructors are also supported. A constructor is named `init`.

```kaze
class Greeter begin
    init <- name begin
        self.name = name
    end

    greet begin
        print("hello, " + self.name + "!\n")
    end
end

var greeter = Greeter("p18f")
greeter.greet() // hello, p18f!
```

## Note on statement termination

In Kaze, statements do not need any terminators like a newline or a semicolon. This is due to expression statements in Kaze being nonexistent except in the REPL and except for a few cases like function calls.

This does mean that if you wish to do something like `true and do_something()`, it won't work. For that, you can assign that to `_` by doing so:

```kaze
var _ = true and do_something()
```

`_` is a special variable name, in the sense that the compiler immediately discards whatever is assigned to it.