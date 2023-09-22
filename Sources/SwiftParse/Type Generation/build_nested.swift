extension Generator {
    
    private typealias AssociatedValue = (label: String, type: String, descriptor: String)
    
    func build_nested(_ lhs: String, _ cases: [NestItem]) throws -> (content: String, fileName: String) {
        
        var string = "\(desiredVisibility) indirect enum \(lhs.nonColliding): CustomStringConvertible {" + lt + lt
        var descriptor = "\(desiredVisibility) var description: String {" + ltt + "switch self {" + ltt
        
        for nestItem in cases {
            build(&string, &descriptor, with: nestItem)
        }
        
        string += lt + descriptor + "}\(lt)}\(lt)\n}\n"
        
        return (string, lhs.CamelCased)
        
    }
    
    private func build(_ string: inout String, _ descriptor: inout String, with nestItem: NestItem) {
        
        let caseName = nestItem.caseName
        let production = nestItem.production
        
        string += "case " + caseName.nonColliding
        descriptor += "case ." + caseName.nonColliding
        
        var usedLabels: [String : Int] = [:]
        
        var associatedValues: [AssociatedValue] = []
        
        var associatedValuesString = ""
        var associatedValuesDescriptor = ""
        
        for rhsComponent in production {
            associatedValues.append(associatedValue(of: rhsComponent, with: &usedLabels))
        }
        
        associatedValuesString += associatedValues.reduce("", {$0 + "_ " + $1.label + ": " + $1.type + ", "}).dropLast(2)
        associatedValuesDescriptor += associatedValues.reduce("", {$0 + "let " + $1.label + ", "}).dropLast(2)
        
        if associatedValues.count > 0 {
            string += "(" + associatedValuesString + ")"
            descriptor += "(" + associatedValuesDescriptor + ")"
        }
        
        descriptor += ": return " + associatedValues.reduce("", {$0 + $1.descriptor + " + "}).dropLast(2)
        
        string += lt
        descriptor += ltt
        
    }
    
    private func associatedValue(of item: RhsItem, with usedLabels: inout [String : Int]) -> AssociatedValue {
        
        let associatedValueLabel: String
        let associatedValueType: String
        let associatedValueDescriptor: String
        
        switch item {
        case .terminal(let type):
            associatedValueLabel = getLabel(&usedLabels, type)
            associatedValueType = "String"
            associatedValueDescriptor = associatedValueLabel
        case .nonTerminal(let name):
            associatedValueLabel = getLabel(&usedLabels, name.camelCased.nonColliding)
            associatedValueType = name.nonColliding
            associatedValueDescriptor = associatedValueLabel + ".description"
        }
        
        return (associatedValueLabel, associatedValueType, associatedValueDescriptor)
        
    }
    
    private func getLabel(_ usedLabels: inout [String : Int], _ expected: String) -> String {
        
        let expected = expected.changeToSwiftIdentifier(use: "_terminal")
        
        if let value = usedLabels[expected] {
            usedLabels[expected]? += 1
            return expected + "\(value)"
        }
        
        usedLabels[expected] = 1
        return expected
        
    }
    
}
