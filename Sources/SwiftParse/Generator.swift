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
    
    func createParser(from specification: String, at path: String, visibility: String = "public", typePath: String?, grammarFile: String?) throws {
        
        self.desiredVisibility = visibility
        
        let tokens = try produceTokens(from: specification)
        
        let statements = try parser.parse(tokens, self)
        
        var swiftSLRSpecificationFile = "SwiftSLRMain -> \(statements.mainItem.swiftSLRToken)\n"
        
        for statement in statements.statements {
            try swiftSLRSpecificationFile.append(statement.asSwiftSLR())
        }
        
        let spreadTypesAcrossMultipleFiles = (typePath != nil)
        
        func typeFilePreamble(_ fileName: String) -> String {
            """
                    
            // \(fileName).swift
            // Auto-generated by SwiftParse
            // See https://github.com/Fleli/SwiftParse
            
            
            """
        }
        
        var types: [(content: String, fileName: String)] = spreadTypesAcrossMultipleFiles ? [] : [(content: typeFilePreamble("Types"), fileName: "Types.swift")]
        
        var converters = """
            
            // Converters.swift
            // Auto-generated by SwiftParse
            // See https://github.com/Fleli/SwiftParse
            
            
            """
        
        let newType: (String, String) -> Void = { content, fileName in
            if spreadTypesAcrossMultipleFiles {
                types.append((typeFilePreamble(fileName) + content, fileName + ".swift"))
            } else {
                types[0].content.append(content)
            }
        }
        
        for list in lists {
            let repeating = list.repeatingItem.arrayTypeName.nonColliding
            let nodeName = list.nonTerminal
            let separator = (list.separator?.swiftSLRToken ?? "") + " "
            converters += generateListConverter(repeating, nodeName, separator)
            swiftSLRSpecificationFile.append(list.asSwiftSLR())
            newType("\(desiredVisibility) typealias \(nodeName.CamelCased.nonColliding) = [\(repeating)]\n\n", nodeName.CamelCased)
        }
        
        for statement in statements.statements {
            let builtType = try build_type(for: statement)
            newType(builtType.content, builtType.fileName)
            converters += try "\(desiredVisibility) extension SLRNode {\n\n\(build_conversion(statement))\n}\n\n"
        }
        
        converters += build_convertToTerminal()
        
        for type in types {
            print("TypePath ?? path: ", typePath ?? path)
            writeToFile(content: type.content, at: (typePath ?? path) + "/" + type.fileName)
        }
        
        writeToFile(content: converters, at: path + "/Converters.swift")
        
        print("SwiftSLR Spec file:")
        print(swiftSLRSpecificationFile)
        
        try SwiftSLR.generate(from: swiftSLRSpecificationFile, includingToken: false, location: path, parseFile: "Parser", visibility: "public")
        
        if let grammarFile {
            let content = "\n\(grammarFile)\nAuto-generated by SwiftParse\nSee https://github.com/Fleli/SwiftParse\n\n" + swiftSLRSpecificationFile
            writeToFile(content: content, at: path + grammarFile)
        }
        
    }
    
    
    private func produceTokens(from input: String) throws -> [Token] {
        
        var tokens = try lexer.lex(input)
        
        for index in 0 ..< tokens.count {
            if tokens[index].type == "terminal" { tokens[index].content.removeFirst() }
        }
        
        return tokens
        
    }
    
    private func generateListConverter(_ elementName: String, _ nodeName: String, _ separator: String) -> String {
        
        let elementName = (elementName == "String") ? "Terminal" : elementName
        
        return """
            \(desiredVisibility) extension SLRNode {
                
                func convertTo\(nodeName.CamelCased)() -> \(nodeName.nonColliding) {
                    
                    if children.count == 0 {
                        return []
                    }
                    
                    if children.count == 1 {
                        return [children[0].convertTo\(elementName)()]
                    }
                    
                    if children.count == 2 {
                        return children[0].convertTo\(nodeName.CamelCased)() + [children[1].convertTo\(elementName)()]
                    }
                    
                    if children.count == 3 {
                        return children[0].convertTo\(nodeName.CamelCased)() + [children[2].convertTo\(elementName)()]
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
