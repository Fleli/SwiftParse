extension Generator {
    
    var t1: String { "\t" }
    var t2: String { t1 + t1 }
    var signatureSuffix: String { " {\n\t\t\n" }
    var convertToTerminalCall: String { "convertToTerminal()" }
    
    func callSyntax(for type: String) -> String {
        return "convertTo\(type.CamelCased)()"
    }
    
    func signature(for type: String) -> String {
        return callSyntax(for: type) + " -> \(type.nonColliding)"
    }
    
    func firstLine(for type: String) -> String {
        return "\tfunc " + signature(for: type) + signatureSuffix
    }
    
    func typeIs(_ expected: String) -> String {
        return "if type == \"" + expected + "\""
    }
    
    func child(_ index: Int, is type: String) -> String {
        let type = (type.first == "#") ? (String(type.dropFirst())) : (type)
        return " && children[" + String(index) + "].type == \"" + type + "\""
    }
    
    func childCountIs(_ count: Int) -> String {
        return " && children.count == \(count)"
    }
    
    func declaration(_ index: Int, _ item: RhsItem) -> String {
        
        let prefix = "let arg\(index) = children[\(index)]."
        
        switch item {
        case .terminal(_):
            return prefix + convertToTerminalCall
        case .nonTerminal(let name):
            return prefix + callSyntax(for: name)
        }
        
    }
    
}
