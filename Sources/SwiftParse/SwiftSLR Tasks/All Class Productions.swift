extension StatementType {
    
    static func findAllCombinations(_ combination: [ClassElement], _ remaining: [ClassElement]) -> [[ClassItem]] {
        
        if remaining.isEmpty {
            
            var returning: [[ClassItem]] = [[]]
            
            for element in combination {
                returning[0] += element.classItems
            }
            
            return returning
            
        }
        
        let next = remaining[0]
        
        if next.required {
            
            let updatedCombination = combination + [next]
            let updatedRemaining = [ClassElement](remaining.dropFirst())
            
            return findAllCombinations(updatedCombination, updatedRemaining)
            
        } else {
            
            let remaining = [ClassElement](remaining.dropFirst())
            
            let option1 = combination
            let result1 = findAllCombinations(option1, remaining)
            
            let option2 = combination + [next]
            let result2 = findAllCombinations(option2, remaining)
            
            return result1 + result2
            
        }
        
    }
    
}
