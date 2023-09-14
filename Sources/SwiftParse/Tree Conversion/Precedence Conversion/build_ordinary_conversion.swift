extension Generator {
    
    func build_ordinary_conversion(_ index: Int, _ lhs: String, _ operators: [RhsItem], _ position: OperatorPosition, _ string: inout String, _ nonTerminal: String, _ infixOperatorCount: inout Int, _ singleArgOperatorCount: inout Int) {
        
        let nextPrefix = "CASE" + (index + 1).toLetters()
        let nextNonTerminal = nextPrefix + lhs
        
        for `operator` in operators {
            
            // Steg 1: Konverter når parseren har sett at operasjonen faktisk utføres
            
            build_operator_conversion(&infixOperatorCount, &singleArgOperatorCount, lhs, nonTerminal, nextNonTerminal, `operator`, position, &string)
            
            // Steg 2: Konverter når den har "gått rett gjennom", dvs. f.eks. Expression -> CASEBExpression er brukt.
            
            string +=
                "\t\t"
            +   typeIs(nonTerminal)
            +   childCountIs(1)
            +   child(0, is: nextNonTerminal)
            +   " {" + lttt + lttt
            +   "return children[0].convertTo\(lhs)()" + lttt + ltt
            +   "}" + ltt + "\n"
            
        }
        
    }
    
}
