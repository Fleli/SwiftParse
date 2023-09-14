public func generateFiles(specification: String, path: String, visibility: String) throws {
    let generator = Generator()
    try generator.createParser(from: specification, at: path, visibility: visibility)
}
