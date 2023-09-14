extension Generator {
    
    func build_enum(_ lhs: String, _ cases: [RhsItem]) throws -> String {
        
        var string = "\(desiredVisibility) enum \(lhs.nonColliding): CustomStringConvertible {" + lt + lt
        
        var descriptionGetter: String = lt + "\(desiredVisibility) var description: String {" + ltt
        descriptionGetter += "switch self {" + ltt
        
        for enumCase in cases {
            
            let caseName: String
            let suffix: String
            
            switch enumCase {
            case .terminal(let type):
                caseName = type
                suffix = ""
            case .nonTerminal(let name):
                caseName = name
                suffix = "(" + name.CamelCased.nonColliding + ")"
            }
            
            string += "case " + caseName.camelCased.nonColliding + suffix + lt
            let convertedSuffix = String(suffix.dropFirst().dropLast()).camelCased.nonColliding
            
            descriptionGetter += "case ." + caseName.camelCased.nonColliding + (suffix.count > 0 ? "(let \(convertedSuffix))" : "") + ": return "
            descriptionGetter += "\(suffix.count > 0 ? convertedSuffix + ".description" : "\"\(caseName)\"")" + ltt
            
        }
        
        string += descriptionGetter + "}" + lt + "}" + lt + "\n}\n"
        
        return string
        
    }
    
}
