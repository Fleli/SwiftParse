extension Generator {
    
    func build_conversion(_ lhs: String, _ groups: [PrecedenceGroup]) throws -> String {
        
        var string = firstLine(for: lhs)
        
        var infixOperatorCount = 0
        var singleArgOperatorCount = 0
        
        for (index, group) in groups.enumerated() {
            
            let prefix = (index > 0) ? "CASE" + index.toLetters() : ""
            let nonTerminal = prefix + lhs
            
            switch group {
            case .ordinary(let position, let operators):
                
                build_ordinary_conversion(index, lhs, operators, position, &string, nonTerminal, &infixOperatorCount, &singleArgOperatorCount)
                
            case .root(let rhs):
                
                build_root_conversion(groups, lhs, rhs, &string)
                
            }
            
        }
        
        return string + "\t\tfatalError()\n\t\t\n\t}\n"
        
    }
    
}
