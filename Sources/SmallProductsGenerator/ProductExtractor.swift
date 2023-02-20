import Foundation
import Crypto
import Core

struct ProductExtractor<T: SmallProductConvertable & Decodable> {

	func start(source: URL, target: URL, datasource: Datasource, languages: [Language] = Language.allCases, showProgress: Bool = true) async throws -> [LanguagePackage] {
		let streamReader = try StreamReader(url: source)
		let fileWriters = createFileWriters(for: languages, outputDirectory: target, filePrefix: "\(datasource.filePrefix)small_products")
		let decoder = JSONDecoder()
		let encoder = JSONEncoder()
		var line: String?
		var extractedProductsCount = 0
		var processedProductsCount = 0
		repeat {
			try customAutoreleasepool {
				line = streamReader.nextLine()
				guard let data = line?.data(using: .utf8) else {
					return
				}
				processedProductsCount += 1
				let product: T
				do {
					product = try decoder.decode(T.self, from: data)
				} catch {
					return
				}
				extractedProductsCount += 1
				
				for (language, name) in product.getNames() where languages.contains(language) {
					let smallProduct = SmallProduct(name: name,
													brand: product.getBrand(),
													barcode: product.getId(),
													energy: product.getEnergy(),
													quantity: product.getQuantity(),
													serving: product.getServing(),
													source: datasource)
					let fileWriter = fileWriters[language]
					try fileWriter?.writeLine(data: try encoder.encode(smallProduct))
				}
				if showProgress && extractedProductsCount % 10000 == 0 {
					print("Processed products: \(processedProductsCount)")
					print("Extracted products: \(extractedProductsCount)")
				}
			}
			
		} while line != nil
		var packages = [LanguagePackage]()
		for (language, fileWriter) in fileWriters {
			let sha256 = fileWriter.finish()
			let createdFiles = [JsonFile(name: fileWriter.url.lastPathComponent, source: datasource, sha256: sha256)]
			let package = LanguagePackage(language: language, files: createdFiles)
			packages.append(package)
		}
		return packages
		do {
			let data = try JSONEncoder().encode(packages)
			try data.write(to: target.appendingPathComponent("overview.json"))
		} catch {
			print("Overview creation failed with error: \(error)")
		}
	}
	
	func createFileHandles(for languages: [Language], outputDirectory: URL, filePrefix: String, initialContent: String = "[") throws -> [Language : FileHandle] {
		var fileHandles = [Language : FileHandle]()
		for language in languages {
			let targetURL = outputDirectory.appendingPathComponent("\(filePrefix)\(language.jsonFilenameSuffix).json")
			try initialContent.write(to: targetURL, atomically: false, encoding: .utf8)
			fileHandles[language] = try FileHandle(forWritingTo: targetURL)
		}
		return fileHandles
	}
	
	func createChunkedFileWriters(for languages: [Language], outputDirectory: URL, filePrefix: String) -> [Language : ChunkedFileWriter] {
		var fileWriters = [Language : ChunkedFileWriter]()
		for language in languages {
			let maxPartSize = 24 * 1024 * 1024 // 24 MiB
			let fileWriter = ChunkedFileWriter(name: "\(filePrefix)\(language.jsonFilenameSuffix)",
										fileExtension: "json",
										directory: outputDirectory,
										maxPartSize: maxPartSize)
			fileWriters[language] = fileWriter
		}
		return fileWriters
	}
	
	func createFileWriters(for languages: [Language], outputDirectory: URL, filePrefix: String) -> [Language : FileWriter] {
		var fileWriters = [Language : FileWriter]()
		for language in languages {
			let fileWriter = FileWriter(name: "\(filePrefix)\(language.jsonFilenameSuffix)",
										fileExtension: "json",
										directory: outputDirectory)
			fileWriters[language] = fileWriter
		}
		return fileWriters
	}
}

extension Language {
	var jsonFilenameSuffix: String {
		switch self {
		case .german:
			return "_de"
		case .english:
			return "_en"
		}
	}
}

extension Datasource {
	var filePrefix: String {
		switch self {
		case .openFoodFacts:
			return "off_"
		case .nutritionPrivacy:
			return "np_"
		}
	}
}

struct LanguagePackage: Codable {
	let language: Language
	let files: [JsonFile]
}

struct JsonFile: Codable {
	let name: String
	let source: Datasource
	let sha256: String
}

public func customAutoreleasepool<Result>(invoking body: () throws -> Result) rethrows -> Result {
	#if !os(Linux)
	return try autoreleasepool(invoking: body)
	#else
	return try body()
	#endif
}

class StreamReader {
	let encoding: String.Encoding
	let chunkSize: Int
	let fileHandle: FileHandle
	var buffer: Data
	let delimiterPattern : Data
	var isAtEOF: Bool = false
	
	init(url: URL, delimiter: String = "\n", encoding: String.Encoding = .utf8, chunkSize: Int = 4096) throws
	{
		print("StreamReader init path:\(url.path)")
		let fileHandle = try FileHandle(forReadingFrom: url)
		self.fileHandle = fileHandle
		self.chunkSize = chunkSize
		self.encoding = encoding
		buffer = Data(capacity: chunkSize)
		delimiterPattern = delimiter.data(using: .utf8)!
	}
	
	deinit {
		fileHandle.closeFile()
	}
	
	func rewind() {
		fileHandle.seek(toFileOffset: 0)
		buffer.removeAll(keepingCapacity: true)
		isAtEOF = false
	}
	
	func nextLine() -> String? {
		if isAtEOF { return nil }
		
		repeat {
			if let range = buffer.range(of: delimiterPattern, options: [], in: buffer.startIndex..<buffer.endIndex) {
				let subData = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
				let line = String(data: subData, encoding: encoding)
				buffer.replaceSubrange(buffer.startIndex..<range.upperBound, with: [])
				return line
			} else {
				let tempData = fileHandle.readData(ofLength: chunkSize)
				if tempData.count == 0 {
					isAtEOF = true
					return (buffer.count > 0) ? String(data: buffer, encoding: encoding) : nil
				}
				buffer.append(tempData)
			}
		} while true
	}
}
extension SHA256Digest {
	var hexString: String {
		self.map { String(format: "%02hhx", $0) }.joined()
	}
}
class FileWriter {
	let url: URL
	private var hasher = SHA256()
	private let stream: OutputStream
	
	init?(name: String, fileExtension: String, directory: URL) {
		let url = createURL(name: name, fileExtension: fileExtension, directory: directory)
		self.url = url
		guard let stream = OutputStream(url: url, append: false) else {
			return nil
		}
		self.stream = stream
	}
	
	func writeLine(data: Data) throws {
		let dataToWrite: Data
		if stream.streamStatus == .notOpen {
			stream.open()
			dataToWrite = data
		} else {
			dataToWrite = .newLineData + data
		}
		try stream.write(data: dataToWrite)
		hasher.update(data: dataToWrite)
	}
	
	func finish() -> String {
		stream.close()
		return hasher.finalize().hexString
	}
}

extension Data {
	static let newLineData = "\n".data(using: .utf8)!
}

class ChunkedFileWriter {
	private let name: String
	private let directory: URL
	private var files: [URL]
	private var currentTargetURL: URL
	private var currentFilePartSize: Int = 0
	private let maxPartSize: Int
	private var currentFileHandle: FileHandle?
	private let fileExtension: String
	private var hasWrittenAtLeastOnce = false
	
	init(name: String, fileExtension: String, directory: URL, maxPartSize: Int) {
		self.name = name
		self.fileExtension = fileExtension
		self.directory = directory
		self.maxPartSize = maxPartSize
		self.files = []
		self.currentTargetURL = createURL(name: name, fileExtension: fileExtension, directory: directory)
	}
	
	func writeLine(data: Data) throws {
		let newLineData = "\n".data(using: .utf8)!
		let dataToWrite = newLineData + data
		if currentFilePartSize + dataToWrite.count >= self.maxPartSize {
			try currentFileHandle?.close()
			currentFileHandle = nil
			var newTargetURL = createURL(name: name, fileExtension: fileExtension, directory: directory, part: files.count)
			if files.isEmpty {
				try FileManager.default.moveItem(at: currentTargetURL, to: newTargetURL)
				currentTargetURL = newTargetURL
				newTargetURL = createURL(name: name, fileExtension: fileExtension, directory: directory, part: files.count + 1)
			}
			files.append(currentTargetURL)
			currentTargetURL = newTargetURL
			currentFilePartSize = 0
		}
		if let currentFileHandle {
			currentFileHandle.write(dataToWrite)
			currentFilePartSize += dataToWrite.count
		} else {
			try data.write(to: currentTargetURL)
			currentFileHandle = try FileHandle(forWritingTo: currentTargetURL)
			currentFileHandle?.seekToEndOfFile()
			currentFilePartSize += data.count
			hasWrittenAtLeastOnce = true
		}
	}
	
	func finish() throws -> [URL] {
		try currentFileHandle?.close()
		if hasWrittenAtLeastOnce {
			files.append(currentTargetURL)
		}
		return files
	}
}

func createURL(name: String, fileExtension: String, directory: URL, part: Int? = nil) -> URL {
	let shouldAddDot = !fileExtension.hasPrefix(".")
	let optionalDot = shouldAddDot ? "." : ""
	let partString: String
	if let part {
		partString = "-\(part)"
	} else {
		partString = ""
	}
	return directory.appendingPathComponent("\(name)\(partString)\(optionalDot)\(fileExtension)")
}
