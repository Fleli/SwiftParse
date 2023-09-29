public func generateFiles(specification: String, path: String, visibility: SwiftVisibility, typeFileOption: FileOption) throws {
    let visibilityKeyword = visibility.rawValue
    let typePath = typeFileOption.typePath
    let generator = Generator()
    try generator.createParser(from: specification, at: path, visibility: visibilityKeyword, typePath: typePath)
}
