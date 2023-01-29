import Foundation

struct DynamicKeyError: Error {}
struct MissingNameError: Error {}
struct MissingUnitError: Error {}

enum DestinationError: Error {
	case existingFileAtTargetPath
	case missingParentDirectory
}
