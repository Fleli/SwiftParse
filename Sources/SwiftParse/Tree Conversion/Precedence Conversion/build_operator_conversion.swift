extension Generator {
    
    // TODO: Refactor dette. Noe må kunne gjøres annerledes når det passes nesten tosifret med argumenter
    func build_operator_conversion(_ infixOperatorCount: inout Int, _ singleArgOperatorCount: inout Int, _ lhs: String, _ nonTerminal: String, _ nextNonTerminal: String, _ `operator`: RhsItem, _ position: OperatorPosition, _ string: inout String) {
        
        var ifStatement = "\t\t" + typeIs(nonTerminal)
        
        switch position {
        case .infix:
            
            ifStatement +=
                childCountIs(3)
            +   child(0, is: nonTerminal)
            +   child(1, is: `operator`.swiftSLRToken)
            +   child(2, is: nextNonTerminal)
            +   " {" + lttt + lttt
            +   "let arg1 = children[0].convertTo\(lhs)()" + lttt
            +   "let arg2 = children[2].convertTo\(lhs)()" + lttt
            +   "return .infixOperator(.operator_\(infixOperatorCount), arg1, arg2)" + lttt + ltt
            
            infixOperatorCount += 1
            
        case .prefix:
            
            ifStatement +=
                childCountIs(2)
            +   child(0, is: `operator`.swiftSLRToken)
            +   child(1, is: nextNonTerminal)
            +   " {" + lttt + lttt
            +   "let arg = children[1].convertTo\(lhs)()" + lttt
            +   "return .singleArgumentOperator(.operator_\(singleArgOperatorCount), arg)" + lttt + ltt
            
            singleArgOperatorCount += 1
            
        case .postfix:
            
            ifStatement +=
                childCountIs(2)
            +   child(0, is: nextNonTerminal)
            +   child(1, is: `operator`.swiftSLRToken)
            +   " {" + lttt + lttt
            +   "let arg = children[0].convertTo\(lhs)()" + lttt
            +   "return .singleArgumentOperator(.operator_\(singleArgOperatorCount), arg)" + lttt + ltt
            
            singleArgOperatorCount += 1
            
        }
        
        string += ifStatement + "}" + ltt + "\n"
        
    }
    
}
