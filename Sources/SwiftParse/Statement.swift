
struct Statement: CustomStringConvertible {
    
    let lhs: String
    let rhs: StatementType
    
    var description: String { lhs + ": " + rhs.description }
    
    func asSwiftSLR() throws -> String {
        return try rhs.convertToSwiftSLR(with: lhs)
    }
    
    func printString() throws {
        let string = try asSwiftSLR()
        print(string)
    }
    
}

enum StatementType: CustomStringConvertible {
    
    case `enum`(cases: [RhsItem])
    case nested(cases: [NestItem])
    case precedence(groups: [PrecedenceGroup])
    case `class`(elements: [ClassElement], allProductions: [[ClassItem]])
    
    var description: String {
        switch self {
        case .enum(let cases):
            return "enum of \(cases)"
        case .nested(let items):
            return "nested of \(items)"
        case .precedence(let groups):
            return "precedence of \(groups)"
        case .class(let elements, _):
            return "class of \(elements)"
        }
    }
    
}

enum RhsItem: CustomStringConvertible, Hashable {
    
    case terminal(type: String)
    case nonTerminal(name: String)
    
    var description: String {
        switch self {
        case .terminal(let type):
            return type
        case .nonTerminal(let name):
            return name
        }
    }
    
    var swiftSLRToken: String {
        switch self {
        case .terminal(let type):
            return "#" + type
        case .nonTerminal(let name):
            return name
        }
    }
    
    var swiftSLRNodeName: String {
        switch self {
        case .terminal(let type):
            return type
        case .nonTerminal(let name):
            return name
        }
    }
    
    var arrayTypeName: String {
        switch self {
        case .terminal(let type):
            return "String"
        case .nonTerminal(let name):
            return name
        }
    }
    
    init?(from token: Token) {
        
        if token.type == "terminal" {
            self = .terminal(type: token.content)
        } else if token.type == "nonTerminal" {
            self = .nonTerminal(name: token.content)
        } else {
            return nil
        }
        
    }
    
}

struct NestItem: CustomStringConvertible {
    
    let caseName: String
    let production: [RhsItem]
    
    var description: String { caseName + " -> " + production.description }
    
}

enum PrecedenceGroup: CustomStringConvertible {
    
    case ordinary(type: OperatorPosition, operators: [RhsItem])
    case root(rhs: [RhsItem])
    
    var description: String {
        switch self {
        case .ordinary(let type, let operators):
            return type.rawValue + ": " + operators.description
        case .root(let rhs):
            return "root -> " + rhs.description
        }
    }
    
    var notRoot: Bool {
        switch self {
        case .ordinary(_, _):
            return true
        case .root(_):
            return false
        }
    }
    
    var isInfix: Bool {
        switch self {
        case .ordinary(.infix, _):
            return true
        default:
            return false
        }
    }
    
    var infixOperators: [RhsItem]? {
        switch self {
        case .ordinary(let type, let operators) where type == .infix:
            return operators
        default:
            return nil
        }
    }
    
    var singleArgumentOperators: [RhsItem]? {
        switch self {
        case .ordinary(let type, let operators) where type != .infix:
            return operators
        default:
            return nil
        }
    }
    
    var isSingleArgument: Bool {
        switch self {
        case .ordinary(.prefix, _), .ordinary(type: .postfix, _):
            return true
        default:
            return false
        }
    }
    
}

enum OperatorPosition: String {
    case prefix = "prefix"
    case infix = "infix"
    case postfix = "postfix"
}

struct ClassElement: CustomStringConvertible {
    
    let required: Bool
    let classItems: [ClassItem]
    
    var description: String {
        return (required ? "!" : "?") + " " + classItems.description
    }
    
    init(_ lineInitializer: String, classItems: [ClassItem]) {
        
        switch lineInitializer {
        case "?":   required = false
        case "!":   required = true
        default:    fatalError()
        }
        
        self.classItems = classItems
        
    }
    
}

enum ClassItem: CustomStringConvertible {
    
    case classField(name: String, type: RhsItem)
    case syntactical(item: RhsItem)
    
    var description: String {
        switch self {
        case .classField(let name, let type):
            return name + ": " + type.description
        case .syntactical(let item):
            return item.description
        }
    }
    
    func inDescriptor(_ forceUnwrap: Bool = false) -> String {
        switch self {
        case .classField(let name, _):
            return "\(name.nonColliding)\(forceUnwrap ? "!" : "").description + \" \""
        case .syntactical(let item):
            return "\"\(item.description) \""
        }
    }
    
    var swiftSLRToken: String {
        
        switch self {
        case .classField(_, let type):
            return type.swiftSLRToken
        case .syntactical(let item):
            return item.swiftSLRToken
        }
        
    }
    
    var asClassField: (name: String, type: RhsItem)? {
        switch self {
        case .classField(let name, let type):
            return (name, type)
        case .syntactical(_):
            return nil
        }
    }
    
    var isClassField: Bool {
        switch self {
        case .classField(_, _):
            return true
        case .syntactical(_):
            return false
        }
    }
    
}
