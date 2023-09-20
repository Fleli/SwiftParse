extension Generator {
    
    // SLRNodes med type T hvor nested T er definert. Dvs returner en enum-case i enum-en T
    func build_conversion(_ lhs: String, _ cases: [NestItem]) throws -> String {
        
        var string = firstLine(for: lhs)
        
        for nestCase in cases {
            
            let caseName = nestCase.caseName
            let production = nestCase.production
            
            var ifStatement = t2 + typeIs(lhs) + childCountIs(production.count)
            
            var declarations: [String] = []         // Hele declaration (Swift-statement)
            
            for (index, rhsItem) in production.enumerated() {
                
                switch rhsItem {
                case .terminal(let type):
                    ifStatement += child(index, is: type)
                case .nonTerminal(let name):
                    ifStatement += child(index, is: name)
                }
                
                declarations.append(declaration(index, rhsItem))
                
            }
            
            ifStatement += " {" + ltt
            
            for declaration in declarations {
                ifStatement += t1 + declaration + ltt
            }
            
            ifStatement += t1 + "return \(lhs.nonColliding).\(caseName.nonColliding)("
            
            if declarations.count >= 2 {
                for index in 0 ..< declarations.count - 1 {
                    ifStatement += "arg\(index), "
                }
            }
            
            ifStatement += "arg\(declarations.count - 1))" + ltt
            
            ifStatement += "}" + lt
            
            string += ifStatement + "\n"
            
        }
        
        string += t2 + "fatalError()\n\t\n\t}\n\t"
        
        return string
        
    }
    
}
