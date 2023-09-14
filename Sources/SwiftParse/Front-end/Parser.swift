class LLParser {
    
    private var index = 0
    private var tokens: [Token] = []
    private var statements: [Statement] = []
    
    private var notExhausted: Bool { index < tokens.count }
    
    private var generator: Generator!
    
    func parse(_ tokens: [Token], _ generator: Generator) throws -> (mainItem: RhsItem, statements: [Statement]) {
        
        self.index = 0
        self.tokens = tokens
        self.statements = []
        
        for i in 0 ..< tokens.count {
            print(i, tokens[i])
        }
        
        self.generator = generator
        
        let mainProduction = try parseMain()
        
        while notExhausted {
            
            let current = tokens[index]
            
            switch current.type {
            case "enum":
                try parseEnum()
            case "nested":
                try parseNested()
            case "precedence":
                try parsePrecedence()
            case "class":
                try parseClass()
            default:
                throw ParseError.unexpected(found: tokens[index].content, expected: "some Statement", location: index)
            }
            
        }
        
        return (mainProduction, statements)
        
    }
    
    
    private func parseEnum() throws {
        
        index += 1
        
        var enumCases: [RhsItem] = []
        
        try assertNextIsAmong("nonTerminal")
        
        let name = tokens[index].content
        
        index += 1
        
        try assertNextIsAmong("{")
        
        index += 1
        
        while notExhausted  &&  tokens[index].type == "case" {
            
            index += 1
            
            let nextToken = tokens[index]
            
            if let item = RhsItem(from: nextToken) {
                enumCases.append(item)
            } else {
                throw ParseError.unexpected(found: nextToken.content, expected: "terminal or nonTerminal", location: index)
            }
            
            index += 1
            
        }
        
        try assertNextIsAmong("}")
        
        index += 1
        
        let newStatement = Statement(lhs: name, rhs: .enum(cases: enumCases))
        statements.append(newStatement)
        
    }
    
    
    private func parseNested() throws {
        
        index += 1
        
        try assertNextIsAmong("nonTerminal")
        
        let name = tokens[index].content
        
        index += 1
        
        try assertNextIsAmong("{")
        
        index += 1
        
        var cases: [NestItem] = []
        
        while notExhausted  &&  tokens[index].type == "case" {
            
            index += 1
            
            let identifier = try nextToken(as: "identifier").content
            let production = try collectItemsUntil(among: "}", "case")
            
            let nestItem = NestItem(caseName: identifier, production: production)
            cases.append(nestItem)
            
        }
        
        try assertNextIsAmong("}")
        
        index += 1
        
        let type = StatementType.nested(cases: cases)
        let nest = Statement(lhs: name, rhs: type)
        
        statements.append(nest)
        
    }
    
    
    private func parsePrecedence() throws {
        
        index += 1
        
        let name = try nextToken(as: "nonTerminal").content
        
        try assertNextIsAmong("{")
        index += 1
        
        var groups: [PrecedenceGroup] = []
        
        while notExhausted {
            
            let type = tokens[index].type
            
            if let operatorPosition = OperatorPosition(rawValue: type) {
                
                index += 1
                
                var items: [RhsItem] = []
                
                while notExhausted, let item = RhsItem(from: tokens[index]) {
                    items.append(item)
                    index += 1
                }
                
                let group = PrecedenceGroup.ordinary(type: operatorPosition, operators: items)
                groups.append(group)
                
            } else if type == ":" {
                
                index += 1
                
                var items: [RhsItem] = []
                
                while notExhausted, let item = RhsItem(from: tokens[index]) {
                    items.append(item)
                    index += 1
                }
                
                let group = PrecedenceGroup.root(rhs: items)
                groups.append(group)
                
            } else if type == "}" {
                
                index += 1
                break
                
            } else {
                
                throw ParseError.unexpected(found: tokens[index].content, expected: "operator position or root production", location: index)
                
            }
            
        }
        
        let statement = Statement(lhs: name, rhs: .precedence(groups: groups))
        statements.append(statement)
        
    }
    
    
    private func parseClass() throws {
        
        index += 1
        
        let name = try nextToken(as: "nonTerminal").content
        
        try assertNextIsAmong("{")
        index += 1
        
        var classElements: [ClassElement] = []
        
        classLoop: while notExhausted {
            
            switch tokens[index].type {
                
            case let lineInitializer where ["!", "?"].contains(lineInitializer):
                
                index += 1
                
                let items: [ClassItem] = try parseClassItems()
                let classElement = ClassElement(lineInitializer, classItems: items)
                classElements.append(classElement)
                
            case "}":
                
                index += 1
                break classLoop
                
            default:
                
                print(classElements)
                throw ParseError.unexpected(found: tokens[index].content, expected: "class element", location: index)
                
            }
            
        }
        
        let all = StatementType.findAllCombinations([], classElements)
        
        let statement = Statement(lhs: name, rhs: .class(elements: classElements, allProductions: all))
        statements.append(statement)
        
    }
    
    
    private func assertNextIsAmong(_ types: String ...) throws {
        
        guard notExhausted else {
            throw ParseError.exhausted(expected: types.description)
        }
        
        let next = tokens[index]
        
        guard types.contains(next.type) else {
            throw ParseError.unexpected(found: next.type, expected: types.description, location: index)
        }
        
    }
    
    
    private func nextToken(as type: String) throws -> Token {
        
        guard notExhausted else {
            throw ParseError.exhausted(expected: type)
        }
        
        try assertNextIsAmong(type)
        
        let token = tokens[index]
        
        index += 1
        
        return token
        
    }
    
    
    private func collectItemsUntil(among endSymbols: String ...) throws -> [RhsComponent] {
        
        var allowed = false
        var collected: [RhsComponent] = []
        
        func parseList() throws -> RhsComponent {
            
            index += 1
            
            guard notExhausted else {
                throw ParseError.exhausted(expected: "list description")
            }
            
            guard let rhsItem = RhsItem(from: tokens[index]) else {
                throw ParseError.unexpected(found: tokens[index].content, expected: "some RhsItem", location: index)
            }
            
            index += 1
            
            guard notExhausted else {
                throw ParseError.exhausted(expected: "list terminator or separator")
            }
            
            if tokens[index].type == "]" {
                generator.insertList(of: rhsItem, with: nil)
                return .list(repeating: rhsItem, separator: nil)
            }
            
            guard index <= tokens.count - 2,
                  tokens[index].type == "|",
                  tokens[index + 1].type == "terminal",
                  tokens[index + 2].type == "]" else {
                throw ParseError.incomplete(expectedPattern: "| separator ]")
            }
            
            let separator = tokens[index + 1].content
            
            index += 2
            
            generator.insertList(of: rhsItem, with: .terminal(type: separator))
            return .list(repeating: rhsItem, separator: .terminal(type: separator))
            
        }
        
        while notExhausted {
            
            let nextToken = tokens[index]
            
            if endSymbols.contains(nextToken.type) {
                allowed = true
                break
            }
            
            if let item = RhsItem(from: nextToken) {
                collected.append(.item(item))
            } else if nextToken.type == "[" {
                try collected.append(parseList())
            } else {
                throw ParseError.unexpected(found: nextToken.content, expected: "some RhsItem ...", location: index)
            }
            
            index += 1
            
        }
        
        guard allowed else {
            print(collected)
            throw ParseError.exhausted(expected: "some RhsItem")
        }
        
        return collected
        
    }
    
    
    private func parseClassItems() throws -> [ClassItem] {
        
        var classItems: [ClassItem] = []
        
        func parseVarDeclaration() throws -> ClassItem {
            
            index += 1
            
            let fieldName = try nextToken(as: "identifier").content
            
            try assertNextIsAmong(":")
            index += 1
            
            guard let type = RhsItem(from: tokens[index]) else {
                throw ParseError.unexpected(found: tokens[index].content, expected: "RhsItem", location: index)
            }
            
            index += 1
            
            return .classField(name: fieldName, type: type)
            
        }
        
        while notExhausted {
            
            switch tokens[index].type {
            case "var":
                
                try classItems.append(parseVarDeclaration())
                
            case "terminal", "nonTerminal":
                
                let item = RhsItem(from: tokens[index])!
                classItems.append(.syntactical(item: item))
                
                index += 1
                
            case "!", "?", "}":
                
                return classItems
                
            default:
                
                throw ParseError.unexpected(found: tokens[index].content, expected: "class item", location: index)
                
            }
            
        }
        
        return classItems
        
    }
    
    private func parseMain() throws -> RhsItem {
        
        try assertNextIsAmong("@main")
        index += 1
        
        let nonTerminal = try nextToken(as: "nonTerminal").content
        
        return .nonTerminal(name: nonTerminal)
        
    }
    
    
}

enum ParseError: Error {
    
    case exhausted(expected: String)
    case unexpected(found: String, expected: String, location: Int)
    case incomplete(expectedPattern: String)
    
}
