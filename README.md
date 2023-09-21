# SwiftParse

SwiftParse is a Simple LR (SLR) parser generator. Both SwiftParse and the resulting parsers are written in Swift. It offers a layer of abstraction over [SwiftSLR](https://github.com/Fleli/SwiftSLR). In addition to calling the SwiftSLR API for the actual parser, SwiftParse does two things:
- It takes the user's specification and forms Swift types that match them
- It defines extension on the `SLRNode` type (the type that makes up the parse tree) to convert the tree so it consists only of user-defined types

## How do I use SwiftParse?

SwiftParse is not organized as a package (though this might change later). Instead, you use its `main.swift` file to tell SwiftParse what should be generated. The `createParser` function of `generator` takes in a `specification` (`String`) and a `path` (`String`). When you run the program, it will (if the specification does not contain errors) generate three files: `Types.swift`, `Converters.swift` and `Parser.swift`. The latter comes from SwiftSLR.

## The SwiftParse specification format

A SwiftParse specification `String` starts with an `@main` statement, starting with the `@main` reserved keyword followed by a non-terminal. This is used to tell the parser what production is final and accepting. An `@main` statement might look like this:

```
@main Main
```

Then comes the actual (abstracted) grammar. SwiftParse offers five types of statements:
- `enum` statements, for simple groups of related but distinct options
- `nested` statements, for extended `enum`s that allow indirection, multiple terminals and non-terminals per case, and lists.
- `precedence` statements, that offer a maintainable, readable and clean syntax for deeply dependent (and recursive) productions
- `class` statements, for types that follow a specific pattern, with some optional and some required parts
- `list` statements, for defining non-terminals that represent Swift arrays

Note: The non-terminal `SwiftSLRMain` is reserved by SwiftParse and should never be used. 

### The `enum` statement

`enum` statements are the simplest of the four. If declarations can start either with the `var` or `let` keywords, an `enum` is perfect:

The SwiftParse syntax for that `enum` would look the following:
```
enum DeclarationPrefix {
    case #let
    case #var
}
```

When SwiftParse sees this statement, it will
- include the `DeclarationPrefix` productions in the grammar that it passes to SwiftSLR
- create a `DeclarationPrefix` type (including `CustomStringConvertible` conformance) in the resulting Swift files so that it can be further used
- generate converter functions so that the raw `SLRNode` tree from SwiftSLR's parser can be converted to user-defined types

The `DeclarationPrefix` type in the resulting `Types.swift` file will look like this:
```
public enum DeclarationKeyword: CustomStringConvertible {
    
    case `let`
    case `var`
    
    public var description: String {
        switch self {
        case .`let`: return "let"
        case .`var`: return "var"
        }
    }
    
}
```

### The `nested` statement

`nested` behaves a bit differently than `enum`s, and allows more flexibility:
- Whereas `enum`s accept exactly one item (terminal or non-terminal) per case, `nested` statements allow an arbitrary number of items (separated by whitespace)
- A `nested` statement requires the `case` keyword to be followed by the actual name of the case, before items can be listed

An example of usage of `nested` statements are for variable/object references that might be
- a variable (base case)
- a member of a reference (recursive)
- calling a reference (recursive)
- subscripting a reference (recursive)

The SwiftParse syntax to express this, would be the following:
```
nested Reference {
    case variable #identifier
    case member Reference #. #identifier
    case call Reference #( Arguments #)
    case subscript Reference #[ Expression #]
}
```
Here, we make use of the list construct in case `call`: A `Reference.call` is a `(` followed by the `Arguments` non-terminal, and then lastly a `)`.

The resulting Swift type for `Reference` is generated automatically and can be found in `Types.swift`:
```
public indirect enum Reference: CustomStringConvertible {
    
    case variable(_ identifier: String)
    case member(_ reference: Reference, _ _terminal: String, _ identifier: String)
    case call(_ reference: Reference, _ _terminal: String, _ arguments: Arguments, _ _terminal1: String)
    case `subscript`(_ reference: Reference, _ _terminal: String, _ expression: Expression, _ _terminal1: String)
    
    public var description: String {
        switch self {
        case .variable(let identifier): return identifier 
        case .member(let reference, let _terminal, let identifier): return reference.description + _terminal + identifier 
        case .call(let reference, let _terminal, let arguments, let _terminal1): return reference.description + _terminal + arguments.description + _terminal1 
        case .`subscript`(let reference, let _terminal, let expression, let _terminal1): return reference.description + _terminal + expression.description + _terminal1 
        }
    }
    
}
```

### The `precedence` statement

A subset of the grammar of many programming languages look similar to this:

```
Sum -> Sum #+ Product
Sum -> Sum #- Product
Sum -> Product
Product -> Product #* Factor
Product -> Product #/ Factor
Product -> Factor
Factor -> #- Base
Factor -> Base
Base -> Reference
Base -> #( Sum #)
```

This way of defining a grammar is very cumbersome and not at all maintainable. The `precedence` statement is built with this in mind. The SwiftParse equivalent of the grammar above is
```
precedence Expression {
    infix #+ #-
    infix #* #/ #%
    prefix #-
    : Reference
    : #( Expression #)
}
```

First, all operators are listed (in order). The first `#+` and `#-` both belong to the first `infix`, telling SwiftParse that they have the same precedence and are infix operators. Similarly, `#*`, `#/` and `#%` all belong to the second `infix` (implying higher precedence than for binary `+` and `-`), while the last `#-` belongs to the `prefix` keyword, implying even higher precedence. The `postfix` keyword is also available.

The lines starting with `infix` and `prefix` (and `postfix` if one is present) represent the `Sum`, `Product` and `Factor` non-terminals above (though they are automatically named very differently internally).

The last two lines, starting with `:`, represents _the root_ of the `precedence` construct. Each root line may have an arbitrary number of items (terminals or non-terminals) and can be recursive. They correspond to the `Base` non-terminal's productions above.

SwiftParse will generate the following `Expression` type in `Types.swift` from this `precedence` statement:
```
public indirect enum Expression: CustomStringConvertible {
    
    public enum InfixOperator: String {
        case operator_0 = "+"
        case operator_1 = "-"
        case operator_2 = "*"
        case operator_3 = "/"
        case operator_4 = "%"
    }
    
    case infixOperator(InfixOperator, Expression, Expression)
    
    public enum SingleArgumentOperator: String {
        case operator_0 = "-"
    }
    
    case singleArgumentOperator(SingleArgumentOperator, Expression)
    
    case Reference(Reference)
    case TerminalExpressionTerminal(String, Expression, String)
    
    public var description: String {
        switch self {
        case .infixOperator(let op, let a, let b): return "\(a.description) \(op.rawValue) \(b.description)"
        case .singleArgumentOperator(let op, let a): return "\(op.rawValue) \(a.description)"
        case .Reference(let reference): return reference.description
        case .TerminalExpressionTerminal(_, let expression, _): return "(" + expression.description + ")"
        }
    }
    
}
```

### The `class` statement

Finally, `class` statements are used whenever several optional and required items should be grouped together to form one non-terminal. In a programming language, this will usually be a good fit for the different statement types. Each line in a `class` statement starts with either `?` (for optional items) or `!` (for required items). An arbitrary number of items can be written per line. Different lines are independent, but if two items are on the same (optional) line, either zero or both must be matched. For instance, the parser will match `let a` and `let a: Int`, but not `let a:` if a Swift-like declaration is defined as follows:

```
class Declaration {
    ! var keyword: DeclarationPrefix
    ! var name: #identifier
    ? #: var type: Type
    ? #= var value: Expression
}
```

Here, we define a `Declaration` as
1. being required to begin with a `DeclarationPrefix`. Since we store this in a `var`, the resulting `Declaration` class will have a `keyword` field to store it
2. being required to have an `identifier` and storing this in a `name` variable
3. Optionally including the `: Type` syntax, storing whatever type is found when parsing in a `type` variable
4. Optionally including the `= Expression` syntax, storing whatever expression is found when parsing in a `value` variable

The resulting `Declaration` in `Types.swift` looks like this:
```
public class Declaration: CustomStringConvertible {
    
    let keyword: DeclarationKeyword
    let name: String
    let type: `Type`?
    let value: Expression?
    
    init(_ keyword: DeclarationKeyword, _ name: String, _ value: Expression) {
        self.keyword = keyword
        self.name = name
        self.type = nil
        self.value = value
    }
    
    init(_ keyword: DeclarationKeyword, _ name: String, _ type: `Type`) {
        self.keyword = keyword
        self.name = name
        self.type = type
        self.value = nil
    }
    
    init(_ keyword: DeclarationKeyword, _ name: String) {
        self.keyword = keyword
        self.name = name
        self.type = nil
        self.value = nil
    }
    
    init(_ keyword: DeclarationKeyword, _ name: String, _ type: `Type`, _ value: Expression) {
        self.keyword = keyword
        self.name = name
        self.type = type
        self.value = value
    }

    public var description: String {
        keyword.description + " " + name.description + " " + (type == nil ? "" : ": " + type!.description + " ") + (value == nil ? "" : "= " + value!.description + " ") + "; "
    }
    
}
```

Here, we see that when `var` appears in the SwiftParse specification, that variable is stored in the resulting `Declaration` object. Also, the class includes four initializers since there are `2 * 2 = 4` (both the type and value are optional) ways to parse a `Declaration`. Note however that the user does not need to understand the initialization system since SwiftParse automatically handles tree conversion.

### The `list` statement



## Inner workings

SwiftParse is divided into 6 steps.

Steps 1 and 2 represent the front-end of SwiftParse. Step 1 uses a [SwiftLex](https://github.com/Fleli/SwiftLex)-generated lexer, and a handwritten LL(1) parser to make sense of the user's specification.

Step 3 uses the result of the front-end to generate a SwiftSLR grammar and a `Set` of `List` instances that are used in step 4 to complete the SwiftSLR grammar.

Step 5 uses the same `[Statement]` to build two files: The _type_ file (which includes `class` and `enum` definitions that are derived from the user's specification) and the
_converter_ file that extends the `SLRNode` class with functions that recursively convert the `SLRNode` tree into a tree the types from the type file.

Step 6 uses SwiftSLR to generate the `SLRParser` class. This is responsible for doing the actual parsing when the user passes in a series of `Token`s.


 Step   | Input             | Output                | Description 
--------|-------------------|-----------------------|------------
1       | `String`          | `[Token]`             | Produce tokens from the user's input (using SwiftLex) 
2       | `[Token]`         | `[Statement]`         | Parse the tokens (recursive descent) and produce statements 
3       | `[Statement]`     | `String`, `Set<List>` | Generate (most of) the SwiftSLR grammar, and find list definitions
4       | `Set<List>`       | `String`              | Extend the SwiftSLR grammar to include list definitions
5       | `[Statement]`     | `String`, `String`    | Generate type definitions and `SLRNode` tree converters, write them to files
6       | `String`          | `String`              | Use SwiftSLR to generate the actual parser and write to a file

## Future Updates

Several updates might come in the future:
1. The `class` statement will support list definitions instead of having to rely on "filler" `nested` statements that clutter the user experience.
2. The `enum` type will probably be removed, and then `nested` will be renamed to `enum` since it really provides a superset of `enum`'s functionality. 

## Commit History

Since SwiftParse did not start out as a package, this repository does not contain its full commit history. To see this, please refer to [SwiftParse-Commits](https://github.com/Fleli/SwiftParse-Commits).
