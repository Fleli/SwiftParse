public enum FileOption {
    
    case singleTypeFile
    case spreadAcrossMultipleFiles(path: String)
    
    internal var typePath: String? {
        switch self {
        case .singleTypeFile:
            return nil
        case .spreadAcrossMultipleFiles(let path):
            return path
        }
    }
    
}
