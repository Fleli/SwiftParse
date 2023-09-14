extension Generator {
    
    func build_conversion(_ lhs: String, _ elements: [ClassElement], _ allProductions: [[ClassItem]]) throws -> String {
        
        var string = firstLine(for: lhs)
        
        for production in allProductions {
            
            var ifStatement = "\t\t" + typeIs(lhs) + childCountIs(production.count)
            var argumentDeclarations: [String] = []
            var initArgs: [String] = []
            
            for (index, classItem) in production.enumerated() {
                
                switch classItem {
                case .classField(_, let type):
                    
                    initArgs.append("arg\(index)")
                    
                    switch type {
                    case .terminal(let type):
                        ifStatement += child(index, is: type)
                        argumentDeclarations.append("let arg\(index) = children[\(index)].\(convertToTerminalCall)")
                    case .nonTerminal(let name):
                        ifStatement += child(index, is: type.swiftSLRNodeName)
                        argumentDeclarations.append("let arg\(index) = children[\(index)].\(callSyntax(for: name))")
                    }
                    
                case .syntactical(let item):
                    ifStatement += child(index, is: item.swiftSLRNodeName)
                }
                
            }
            
            ifStatement += " {\n"
            
            argumentDeclarations.forEach { ifStatement += "\t\t\t" + $0 + "\n" }
            
            ifStatement += "\t\t\treturn .init(" + initArgs.convertToList(", ") + ")\n\t\t}\n\t\t"
            
            string += ifStatement + "\n"
            
        }
        
        string += "\t\tfatalError()\n\t\t\n\t}\n"
        
        return string
        
    }
    
}
