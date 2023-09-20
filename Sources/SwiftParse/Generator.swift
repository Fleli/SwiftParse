import Foundation
import SwiftSLR

class Generator {
    
    let lexer = Lexer()
    let parser = LLParser()
    
    var desiredVisibility = "internal"
    
    struct List: Hashable {
        
        let repeatingItem: RhsItem
        let separator: RhsItem?
        let nonTerminal: String
        
        func asSwiftSLR() -> String {
            
            var string = "\(nonTerminal) -> \(nonTerminal) \(separator == nil ? "" : separator!.swiftSLRToken + " ")\(repeatingItem.swiftSLRToken)\n"
            string += "\(nonTerminal) -> \(repeatingItem.swiftSLRToken)\n"
            string += "\(nonTerminal) ->\n"
            
            return string
            
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(repeatingItem)
            hasher.combine(separator)
            hasher.combine(nonTerminal)
        }
        
    }
    
    private var lists: Set<List> = []
    
    func createParser(from specification: String, at path: String, visibility: String = "public") throws {
        
        self.desiredVisibility = visibility
        
        let tokens = try produceTokens(from: specification)
        
        let statements = try parser.parse(tokens, self)
        
        var swiftSLRSpecificationFile = "Program -> \(statements.mainItem.swiftSLRToken)\n"
        
        for statement in statements.statements {
            try swiftSLRSpecificationFile.append(statement.asSwiftSLR())
        }
        
        var types = ""
        var converters = ""
        
        for list in lists {
            let nodeName = list.repeatingItem.swiftSLRNodeName
            let separator = (list.separator?.swiftSLRToken ?? "") + " "
            converters += generateListConverter(nodeName, separator)
            swiftSLRSpecificationFile.append(list.asSwiftSLR())
        }
        
        for statement in statements.statements {
            types += try build_type(for: statement) + "\n"
            converters += try "\(desiredVisibility) extension SLRNode {\n\n\(build_conversion(statement))\n}\n\n"
        }
        
        converters += build_convertToTerminal()
        
        writeToFile(content: types, at: path + "/" + "Types.swift")
        writeToFile(content: converters, at: path + "/" + "Converters.swift")
        
        print("SwiftSLR Spec file:")
        print(swiftSLRSpecificationFile)
        
        try SwiftSLR.generate(from: swiftSLRSpecificationFile, includingToken: false, location: path, parseFile: "Parser", visibility: "public")
        
    }
    
    
    private func produceTokens(from input: String) throws -> [Token] {
        
        var tokens = try lexer.lex(input)
        
        for index in 0 ..< tokens.count {
            if tokens[index].type == "terminal" { tokens[index].content.removeFirst() }
        }
        
        return tokens
        
    }
    
    private func generateListConverter(_ nodeName: String, _ separator: String) -> String {
        return """
            \(desiredVisibility) extension SLRNode {
                
                func convertTo\(nodeName.CamelCased)LIST() -> [\(nodeName.nonColliding)] {
                    
                    if children.count == 0 {
                        return []
                    }
                    
                    if children.count == 1 {
                        return [children[0].convertTo\(nodeName.CamelCased)()]
                    }
                    
                    if children.count == 2 {
                        return children[0].convertTo\(nodeName.CamelCased)LIST() + [children[1].convertTo\(nodeName.CamelCased)()]
                    }
                    
                    if children.count == 3 {
                        return children[0].convertTo\(nodeName.CamelCased)LIST() + [children[2].convertTo\(nodeName.CamelCased)()]
                    }
                    
                    fatalError()
                    
                }
                
            }
            
            """
    }
    
    func insertList(of repeating: RhsItem, with separator: RhsItem?, named nonTerminal: String) {
        lists.insert(.init(repeatingItem: repeating, separator: separator, nonTerminal: nonTerminal))
    }
    
    func writeToFile(content: String, at path: String) {
        
        let fileManager = FileManager()
        let didCreate = fileManager.createFile(atPath: path, contents: content.data(using: .utf8))
        print("didCreate:", didCreate)
        
    }
    
}
