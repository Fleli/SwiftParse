extension Generator {
    
    func build_enum(_ lhs: String, _ cases: [RhsItem]) throws -> (content: String, fileName: String) {
        
        var string = "\(desiredVisibility) enum \(lhs.nonColliding): CustomStringConvertible {" + lt + lt
        
        var descriptionGetter: String = lt + "\(desiredVisibility) var description: String {" + ltt
        descriptionGetter += "switch self {" + ltt
        
        for enumCase in cases {
            
            var caseName: String
            let suffix: String
            
            switch enumCase {
            case .terminal(let type):
                caseName = type
                suffix = ""
            case .nonTerminal(let name):
                caseName = name
                suffix = "(" + name.CamelCased.nonColliding + ")"
            }
            
            let nonCollidingCaseName = caseName.camelCased.nonColliding
            
            string += "case " + nonCollidingCaseName + suffix + lt
            let convertedSuffix = String(suffix.dropFirst().dropLast()).camelCased.nonColliding
            
            descriptionGetter += "case ." + nonCollidingCaseName + (suffix.count > 0 ? "(let \(convertedSuffix))" : "") + ": return "
            descriptionGetter += "\(suffix.count > 0 ? convertedSuffix + ".description" : "\"\(caseName)\"")" + ltt
            
        }
        
        string += descriptionGetter + "}" + lt + "}" + lt + "\n}\n"
        
        return (string, lhs.CamelCased)
        
    }
    
}
