extension Generator {
    
    func build_conversion(_ statement: Statement) throws -> String {
        
        let lhs = statement.lhs
        let type = statement.rhs
        
        switch type {
            
        case .enum(let cases):
            
            return try build_conversion(lhs, cases)
            
        case .nested(let cases):
            
            return try build_conversion(lhs, cases)
            
        case .precedence(let groups):
            
            return try build_conversion(lhs, groups)
            
        case .class(let elements, let allProductions):
            
            return try build_conversion(lhs, elements, allProductions)
            
        }
        
    }
    
}
