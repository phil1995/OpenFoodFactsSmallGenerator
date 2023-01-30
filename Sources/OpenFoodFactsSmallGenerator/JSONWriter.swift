import Foundation

class JSONWriter {
	let fileURL: URL
	private var existingFileHandle: FileHandle?
	
	init(fileURL: URL) {
		self.fileURL = fileURL
	}
	
	func write(data: Data) throws {
		if let existingFileHandle {
			writeDataWithFileHandle(data: data, fileHandle: existingFileHandle)
		} else if let newFileHandle = try? FileHandle(forWritingTo: fileURL) {
			writeDataWithFileHandle(data: data, fileHandle: newFileHandle)
			existingFileHandle = newFileHandle
		} else {
			try data.write(to: fileURL)
		}
	}
	
	private func writeDataWithFileHandle(data: Data, fileHandle: FileHandle) {
		fileHandle.seekToEndOfFile()
		fileHandle.write(data)
	}
	
	deinit {
		existingFileHandle?.closeFile()
	}
}
