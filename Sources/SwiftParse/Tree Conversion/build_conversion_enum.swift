extension Generator {
    
    // If: "enum A { case p; case q; ... }", this function converts from the SLRNode with type 'A'. So this might return 'A.p'.
    func build_conversion(_ lhs: String, _ cases: [RhsItem]) throws -> String {
        
        var string = firstLine(for: lhs)
        
        for enumCase in cases {
            switch enumCase {
            case .terminal(let type):
                string += """
                        \(typeIs(lhs) + child(0, is: type)) {
                            return \(lhs).\(type.camelCased.nonColliding)
                        }
                        
                
                """
            case .nonTerminal(let name):
                string += """
                        \(typeIs(lhs))\(child(0, is: name)) {
                            let nonTerminalNode = children[0].\(callSyntax(for: name))
                            return \(lhs.nonColliding).\(name.camelCased.nonColliding)(nonTerminalNode)
                        }\(lt)\n
                """
            }
        }
        
        string += """
                fatalError()
                
            }
        
        """
        
        return string
        
    }
    
}
