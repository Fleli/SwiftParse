extension StatementType {
    
    
    func convertToSwiftSLR(with lhs: String) throws -> String {
        
        switch self {
        case .enum(let cases):
            return try Self.enumCasesToString(cases, lhs)
        case .nested(let cases):
            return try Self.nestedCasesToString(cases, lhs)
        case .precedence(let groups):
            return try Self.precedenceToString(groups, lhs)
        case .class(let elements, _):
            return try Self.classToString(elements, lhs)
        }
        
    }
    
    private static func enumCasesToString(_ cases: [RhsItem], _ lhs: String) throws -> String {
        
        var string = ""
        
        for enumCase in cases {
            
            string += lhs + " -> " + enumCase.swiftSLRToken + "\n"
            
        }
        
        return string
        
    }
    
    private static func nestedCasesToString(_ cases: [NestItem], _ lhs: String) throws -> String {
        
        var string = ""
        
        for nestItem in cases {
            
            string += lhs + " -> "
            
            for rhsItem in nestItem.production {
                
                string += rhsItem.swiftSLRToken + " "
                
            }
            
            string += "\n"
            
        }
        
        return string
        
    }
    
    private static func precedenceToString(_ groups: [PrecedenceGroup], _ lhs: String) throws -> String {
        
        var string = ""
        
        let lastGroup = groups.filter { $0.notRoot }.count
        let rootPrefix = "CASE" + lastGroup.toLetters()
        
        for (index, group) in groups.enumerated() {
            
            let indexPrefix = index.toLetters()
            let ntPrefix = index > 0 ? "CASE" + indexPrefix : ""
            
            switch group {
            case .ordinary(let type, let operators):
                
                let autoLHS = ntPrefix + lhs
                let nextLHS = "CASE" + (index + 1).toLetters() + lhs
                
                switch type {
                case .prefix:
                    
                    for _operator in operators {
                        string += autoLHS + " -> " + _operator.swiftSLRToken + " " + nextLHS + "\n"
                    }
                    
                case .infix:
                    
                    for _operator in operators {
                        string += autoLHS + " -> " + autoLHS + " " + _operator.swiftSLRToken + " " + nextLHS + "\n"
                    }
                    
                case .postfix:
                    
                    for _operator in operators {
                        string += autoLHS + " -> " + nextLHS + " " + _operator.swiftSLRToken + "\n"
                    }
                    
                }
                
                string += autoLHS + " -> " + nextLHS + "\n"
                
            case .root(let rhs):
                
                string += rootPrefix + lhs + " -> " + rhs.produceSwiftSLRSyntax() + "\n"
                
            }
            
        }
        
        return string
        
    }
    
    private static func classToString(_ elements: [ClassElement], _ lhs: String) throws -> String {
        
        var string = ""
        
        let allCombinations = findAllCombinations([], elements)
        
        for combination in allCombinations {
            string += lhs + " -> " + combination.produceSwiftSLRSyntax() + "\n"
        }
        
        return string
        
    }
    
}
