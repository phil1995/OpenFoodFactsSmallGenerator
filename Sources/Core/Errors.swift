import Foundation

public enum ProductDecodingError: Error {
	case dynamicKeyFailed
	case missingName
	case missingUnit
}

public enum DestinationError: Error {
	case existingFileAtTargetPath
	case missingParentDirectory
}
