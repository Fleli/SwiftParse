extension Generator {
    
    private struct ClassField: CustomStringConvertible, Equatable, Hashable {
        
        let required: Bool
        
        let name: String
        let type: String
        
        var swiftSyntax: String { "let " + swiftSignature }
        var swiftSignature: String { name.nonColliding + ": " + type.nonColliding + (required ? "" : "?") }
        var description: String { swiftSyntax }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(type)
        }
        
        init(_ required: Bool, _ name: String, _ type: String) {
            self.required = required
            self.name = name
            self.type = type.changeToSwiftIdentifier(use: "String")
        }
        
        static func == (lhs: ClassField, rhs: ClassField) -> Bool {
            return lhs.name == rhs.name && lhs.type == rhs.type
        }
        
    }
    
    private struct Initializer: Hashable {
        
        let allFields: [ClassField]
        let chosenFields: [ClassField]
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(allFields)
            hasher.combine(chosenFields)
        }
        
        var swiftSyntax: String {
            
            let signatureArgumentList = chosenFields.map { "_ " + $0.swiftSignature }.convertToList(", ")
            
            let initLines = allFields
                .map { (name: $0.name, isNil: !chosenFields.contains($0)) }
                .map { "\t\tself.\($0.name) = \($0.isNil ? "nil" : $0.name)\n" }
                .reduce("") { $0 + $1 }
            
            return "\t\n\tinit(\(signatureArgumentList)) {\n\(initLines)\t}\n"
            
        }
        
        init(_ allFields: [ClassField], _ chosenFields: [ClassField]) {
            self.allFields = allFields
            self.chosenFields = chosenFields
        }
        
    }
    
    func build_class(_ lhs: String, _ elements: [ClassElement], _ allProductions: [[ClassItem]]) throws -> String {
        
        var string = "\(desiredVisibility) class \(lhs.nonColliding): CustomStringConvertible {" + lt + "\n"
        
        let descriptionGetter: String = lt + "\(desiredVisibility) var description: String {" + ltt + elements.map({ descriptor($0) }).reduce("", { $0 + " + " + $1 }).dropFirst(3) + lt + "}" + lt
        print("Description Getter: \(descriptionGetter)")
        
        let fields = classFields(elements)
        
        for field in fields {
            string += "\t" + field.swiftSyntax + "\n"
        }
        
        for initializer in initializers(fields, allProductions) {
            string += initializer.swiftSyntax
        }
        
        string += "\(descriptionGetter)\n}\n"
        
        return string
        
    }
    
    private func classFields(_ elements: [ClassElement]) -> [ClassField] {
        
        var fields: [ClassField] = []
        
        for element in elements {
            
            let required = element.required
            let items = element.classItems
            
            for item in items {
                
                switch item {
                case .classField(let name, let type):
                    
                    let fieldType = type.swiftSLRToken.changeToSwiftIdentifier(use: "String")
                    let field = ClassField(required, name, fieldType)
                    fields.append(field)
                    
                case .syntactical(_):
                    break
                }
                
            }
            
        }
        
        return fields
        
    }
    
    private func initializers(_ fields: [ClassField], _ allProductions: [[ClassItem]]) -> [Initializer] {
        
        var initializers: Set<Initializer> = []
        
        print("Class: All productions: \(allProductions)")
        
        for production in allProductions {
            
            let chosenFields = production
                .compactMap { $0.asClassField }
                .map { ClassField(true, $0.name, $0.type.swiftSLRToken) }
            
            let newInitializer = Initializer(fields, chosenFields)
            print("Added initializer: \(newInitializer)")
            initializers.insert(newInitializer)
            
        }
        
        return [Initializer](initializers)
        
    }
    
    private func descriptor(_ element: ClassElement) -> String {
        
        let variables = element.classItems.compactMap({$0.asClassField})
        
        if element.required {
            
            return String(element.classItems.map {$0.inDescriptor(false)}.reduce("", {$0 + " + " + $1}).dropFirst(3))
            
        } else if let deciding = variables.first {
            
            return "(\(deciding.name) == nil ? \"\" : " + element.classItems.map {$0.inDescriptor(true)}.reduce("", {$0 + " + " + $1}).dropFirst(3) + ")"
            
        }
        
        return ""
        
    }
    
}
