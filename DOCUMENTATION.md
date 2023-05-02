Welcome to kaze! Kaze is a simple interpreted kanguage built for scripting, with a minimal syntax inspired by Ruby, Hana and Lox designed for ease of use. Enjoy your stay!

Please note that this is experimental software, and things have a high chance of breaking.

# Syntax

A program in Kaze consists of statements, seperated by newlines. No semicolons required!

## variables

Variables are dynamically declared using the `var` keyword, and may or may not be assigned to at the time of declaration:

```kaze
var a = 1
var b
```

If you try to use an unitialized variable, the interpreter will throw an error!

```kaze
var undec

println undec // "Variable "undec" not assigned to a value."
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
    println "hello!"
end

hello_there() //=> "hello!"
```

Or with params:

```kaze
fun greet <- greeting begin
    println greeting
end

greet("hey!") //=> "hey!"
```