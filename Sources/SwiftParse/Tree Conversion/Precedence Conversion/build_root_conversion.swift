extension Generator {
    
    func build_root_conversion(_ groups: [PrecedenceGroup], _ lhs: String, _ rhs: [RhsItem], _ string: inout String) {
        
        let lastGroup = groups.filter { $0.notRoot }.count
        let rootPrefix = "CASE" + lastGroup.toLetters()
        let nonTerminal = rootPrefix + lhs
        
        var declarations: [String] = []
        
        var ifStatement =
            "\t\t"
        +   typeIs(nonTerminal)
        +   childCountIs(rhs.count)
        
        var caseName = ""
        
        for (index, rhsItem) in rhs.enumerated() {
            switch rhsItem {
            case .terminal(let type):
                ifStatement += child(index, is: type)
                declarations.append("let arg\(index) = children[\(index)].convertToTerminal()")
                caseName += type.changeToSwiftIdentifier(use: "Terminal")
            case .nonTerminal(let name):
                ifStatement += child(index, is: name)
                declarations.append("let arg\(index) = children[\(index)].convertTo\(name)()")
                caseName += name
            }
        }
        
        string +=
            ifStatement
        +   " {" + lttt + lttt
        
        var returnStatement = "return ." + caseName + "("
        
        for (index, declaration) in declarations.enumerated() {
            
            string += declaration + lttt
            
            returnStatement.append("arg\(index)")
            
            if index < declarations.count - 1 {
                returnStatement.append(", ")
            }
            
        }
        
        string += returnStatement + ")" + lttt + ltt + "}" + ltt + "\n"
        
    }
    
}
