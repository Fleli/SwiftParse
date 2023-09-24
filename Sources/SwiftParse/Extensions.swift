import Foundation

extension Int {
    
    func toLetters() -> String {
        
        var symbolValues: [Int] = []
        
        var _self = self
        let modulus = 26
        
        while _self >= 0 {
            
            let value = _self % modulus
            symbolValues.append(value)
            
            _self -= value
            _self /= modulus
            
            if _self == 0 {
                break
            }
            
        }
        
        var string = ""
        
        for value in symbolValues {
            let character = Character(UnicodeScalar(65 + value)!)
            string.insert(character, at: string.startIndex)
            
        }
        
        return string
        
    }
    
}

extension [RhsItem] {
    
    func produceSwiftSLRSyntax() -> String {
        
        var string = ""
        
        for item in self {
            string += item.swiftSLRToken + " "
        }
        
        return string
        
    }
    
}

extension [ClassItem] {
    
    func produceSwiftSLRSyntax() -> String {
        
        var string = ""
        
        for item in self {
            string += item.swiftSLRToken + " "
        }
        
        return string
        
    }
    
}

extension String {
    
    private static let swiftKeywords = [
        "associativity", "async", "await", "break", "case", "catch", "class", "continue", "default", "defer",
        "deinit", "do", "else", "enum", "extension", "false", "fileprivate", "final", "for", "func", "get",
        "guard", "if", "import", "in", "infix", "init", "inout", "internal", "is", "lazy", "left", "let", "nil",
        "none", "nonmutating", "open", "operator", "optional", "override", "postfix", "precedence", "prefix",
        "private", "protocol", "public", "repeat", "required", "rethrows", "return", "right", "self", "set",
        "static", "struct", "subscript", "super", "switch", "throw", "throws", "true", "try", "try?", "try!",
        "typealias", "unowned", "var", "weak", "where", "while", "Type", "Self", "assignment"
    ]
    
    private static let invalidCharacters: [Character: String] = [
        ",": "comma_",
        "(": "leftParenthesis_",
        ")": "rightParenthesis_",
        "'": "apostrophe_",
        "!": "exclamationMark_",
        "@": "atSymbol_",
        "#": "hashSymbol_",
        "%": "percentSign_",
        "*": "asterisk_",
        "+": "plusSign_",
        "-": "hyphen_",
        "/": "slash_",
        ":": "colon_",
        ";": "semicolon_",
        "<": "lessThan_",
        "=": "equalsSign_",
        ">": "greaterThan_",
        "?": "questionMark_",
        "[": "leftSquareBracket_",
        "]": "rightSquareBracket_",
        "{": "leftCurlyBrace_",
        "}": "rightCurlyBrace_",
        "|": "verticalBar_",
        "~": "tilde_",
        " ": "space_",
        ".": "period_",
        "&": "ampersand_",
        "$": "dollarSign_"
    ]



    
    // TODO: Backtick self if Swift keyword
    var nonColliding: String {
        
        if Self.swiftKeywords.contains(self) {
            
            return "`\(self)`"
            
        } else {
            
            var isIllegal = false
            
            let adjusted: String = self.map { (c: Character) -> String in
                
                if c.isLetter {
                    return "\(c)"
                } else if let coveredCase = Self.invalidCharacters[c] {
                    isIllegal = true
                    return coveredCase
                } else {
                    isIllegal = true
                    return "\(c.asciiValue ?? 8)"
                }
                
            }.reduce("_", {$0 + $1})
            
            return isIllegal ? adjusted : self
            
        }
        
    }
    
    var camelCased: String {
        
        guard let first = first else {
            return ""
        }
        
        return first.lowercased() + self[index(after: startIndex) ..< endIndex]
        
    }
    
    var CamelCased: String {
        
        guard let first = first else {
            return ""
        }
        
        return first.uppercased() + self[index(after: startIndex) ..< endIndex]
        
    }
    
    func changeToSwiftIdentifier(use backup: String) -> String {
        
        for c in self {
            if !"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".contains(c) {
                return backup
            }
        }
        
        return self
        
    }
    
}

extension Array where Element: CustomStringConvertible {
    
    func convertToList(_ separator: String) -> String {
        
        var string = ""
        
        for (index, element) in enumerated() {
            
            string += element.description
            
            if index < count - 1 {
                string += "\(separator)"
            }
            
        }
        
        return string
        
    }
    
}
