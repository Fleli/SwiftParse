public func generateFiles(specification: String, path: String, visibility: String, spreadTypesAcrossMultipleFiles: Bool) throws {
    let generator = Generator()
    try generator.createParser(from: specification, at: path, visibility: visibility, spreadTypesAcrossMultipleFiles: spreadTypesAcrossMultipleFiles)
}
