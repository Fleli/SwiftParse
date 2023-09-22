extension Generator {
    
    func build_precedence(_ lhs: String, _ groups: [PrecedenceGroup]) throws -> (content: String, fileName: String) {
        
        typealias Operators = [RhsItem]
        
        let swiftType = lhs.nonColliding
        
        var descriptor = "\(desiredVisibility) var description: String {" + ltt + "switch self {" + ltt
        
        var string = desiredVisibility + " indirect enum \(swiftType): CustomStringConvertible {\n\t\n"
        
        let twoArgumentNonRoots = groups.compactMap { $0.infixOperators }
        let ta = twoArgumentNonRoots.reduce([], { $0 + $1 } )
        let taCount = twoArgumentNonRoots.map({ $0.count }).reduce(0, { $0 + $1 })
        
        print("Two argument non roots of \(lhs): \(twoArgumentNonRoots.count) \(twoArgumentNonRoots)")
        
        if taCount > 0 {
            
            descriptor += "case .infixOperator(let op, let a, let b): return \"(\\(a.description) \\(op.rawValue) \\(b.description))\"" + ltt
            
            string += "\t\(desiredVisibility) enum InfixOperator: String {\n\t"
            
            for index in 0 ..< taCount {
                string += "\tcase operator_\(index) = \"\(ta[index])\"\n\t" // TODO: Endre syntax slik at brukeren velger hva operatoren skal hete i denne enum-en. MERK: Det krever også endring i parseren og PrecedenceGroup-enum-en.
            }
            
            string += "}\n"
            
            string += "\t\n\tcase infixOperator(InfixOperator, \(lhs), \(lhs))\n\t\n"
            
        }
        
        let singleArgumentNonRoots = groups.compactMap { $0.singleArgumentOperators }
        let sa = singleArgumentNonRoots.reduce([], { $0 + $1 })
        let saCount = sa.count
        
        print("Single argument non roots of \(lhs): \(singleArgumentNonRoots.count) \(singleArgumentNonRoots)")
        
        if saCount > 0 {
            
            descriptor += "case .singleArgumentOperator(let op, let a): return \"(\\(op.rawValue) \\(a.description))\"" + ltt
            
            string += "\t\(desiredVisibility) enum SingleArgumentOperator: String {\n\t"
            
            for index in 0 ..< saCount {
                string += "\tcase operator_\(index) = \"\(sa[index])\"\n\t" // TODO: Endre syntax slik at brukeren velger hva operatoren skal hete i denne enum-en. MERK: Det krever også endring i parseren og PrecedenceGroup-enum-en.
            }
            
            string += "}\n\t\n\tcase singleArgumentOperator(SingleArgumentOperator, \(lhs))\n\t\n"
            
        }
        
        for group in groups {
            
            switch group {
            case .ordinary(_, _):
                break
            case .root(let rhs):
                let rootBuildResult = build_precedence_root(rhs)
                string += rootBuildResult.caseLine
                descriptor += build_root_descriptor(rootBuildResult.caseName, rootBuildResult.associatedValues, rhs)
            }
            
        }
        
        string += lt + descriptor + "}" + lt + "}" + lt
        
        string += "\n}\n"
        
        return (string, lhs.CamelCased)
        
    }
    
    private typealias RootBuildResult = (caseName: String, caseLine: String, associatedValues: [String])
    
    private func build_precedence_root(_ rhs: [RhsItem]) -> RootBuildResult {
        
        var string = ""
        var associatedValues: [String] = []
        
        var result: RootBuildResult = ("", "", [])
        
        for item in rhs {
            switch item {
            case .terminal(let type):
                string += type.changeToSwiftIdentifier(use: "Terminal")
                associatedValues.append("String")
            case .nonTerminal(let name):
                string += name
                associatedValues.append(name)
            }
        }
        
        result.caseName = string
        result.associatedValues = associatedValues
        
        string = "\tcase " + string + "("
        
        if rhs.count >= 2 {
            for index in (0 ..< rhs.count - 1) {
                string += associatedValues[index] + ", "
            }
        }
        
        string += associatedValues.last! + ")"
        
        string += "\n"
        
        result.caseLine = string
        
        return result
        
    }
    
    private func build_root_descriptor(_ caseName: String, _ associatedValues: [String], _ rhs: [RhsItem]) -> String {
        
        var part1 = "case .\(caseName)("
        var part2 = "return "
        
        var nameCounter: [String : Int] = [:]
        
        for (index, associatedValue) in associatedValues.enumerated() {
            
            var adjusted = associatedValue.camelCased.nonColliding
            
            if let count = nameCounter[adjusted] {
                nameCounter[adjusted] = count + 1
                adjusted += "_\(count)"
            } else {
                nameCounter[adjusted] = 1
            }
            
            switch rhs[index] {
            case .nonTerminal(_):
                part1 += "let " + adjusted + ", "
                part2 += "\(adjusted).description + "
            case .terminal(let type):
                part1 += "_, "
                part2 += "\"\(type)\" + "
            }
            
        }
        
        return part1.dropLast(2) + "): " + part2.dropLast(3) + ltt
        
    }
    
}
