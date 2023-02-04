import XCTest
@testable import OpenFoodFactsSmallGenerator

final class FileWriterTests: XCTestCase {

	var tmpDirectory: URL!
	var testUnit: FileWriter!
	let defaultName = "Test"
	let defaultFileExtension = ".txt"
	
	override func setUpWithError() throws {
		tmpDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
		try FileManager.default.createDirectory(at: tmpDirectory, withIntermediateDirectories: false)
		testUnit = FileWriter(name: defaultName, fileExtension: defaultFileExtension, directory: tmpDirectory)
	}

	override func tearDownWithError() throws {
		try FileManager.default.removeItem(at: tmpDirectory)
	}

	func test_write_singleFile() throws {
		try testUnit.writeLine(data: "Test 1".data(using: .utf8)!)
		try testUnit.writeLine(data: "Test 2".data(using: .utf8)!)
		testUnit.finish()
		let expectedFileURL = tmpDirectory.appendingPathComponent("Test.txt")
		XCTAssertEqual(testUnit.url, expectedFileURL)
		
		let fileContent = try String(contentsOf: expectedFileURL, encoding: .utf8)
		
		XCTAssertEqual(fileContent, "Test 1\nTest 2")
	}
	
	func test_write_toExistingFile_overwrites_content() throws {
		// GIVEN
		// Old content has been written
		testUnit = FileWriter(name: defaultName, fileExtension: defaultFileExtension, directory: tmpDirectory)
		try testUnit.writeLine(data: "Old content".data(using: .utf8)!)
		testUnit.finish()
		let oldFileURL = testUnit.url
		
		// WHEN
		// A new FileWriter gets initialized for a existing file
		testUnit = FileWriter(name: defaultName, fileExtension: defaultFileExtension, directory: tmpDirectory)
		// And the new FileWriter writes lines to the file
		try testUnit.writeLine(data: "Test 1".data(using: .utf8)!)
		try testUnit.writeLine(data: "Test 2".data(using: .utf8)!)
		let newFileURL = testUnit.url
		
		// THEN
		// The old and the new url are the same
		XCTAssertEqual(newFileURL, oldFileURL)
		
		let expectedFileURL = tmpDirectory.appendingPathComponent("Test.txt")
		// The content has been overwritten with the new content
		let fileContent = try String(contentsOf: expectedFileURL, encoding: .utf8)
		XCTAssertEqual(fileContent, "Test 1\nTest 2")
	}
}
