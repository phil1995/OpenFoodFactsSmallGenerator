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
		testUnit = FileWriter(name: defaultName, fileExtension: defaultFileExtension, directory: tmpDirectory, maxPartSize: 10 * 1024 * 1024)
    }

    override func tearDownWithError() throws {
		try FileManager.default.removeItem(at: tmpDirectory)
    }

    func test_write_singleFile() throws {
		try testUnit.writeLine(data: "Test 1".data(using: .utf8)!)
		try testUnit.writeLine(data: "Test 2".data(using: .utf8)!)
		let urls = try testUnit.finish()
		let expectedFileURL = tmpDirectory.appendingPathComponent("Test.txt")
		XCTAssertEqual(urls, [expectedFileURL])
		
		let fileContent = try String(contentsOf: expectedFileURL, encoding: .utf8)
		
		XCTAssertEqual(fileContent, "Test 1\nTest 2")
    }
	
	func test_write_moreThanMaxPartSize_createsMultipleFiles() throws {
		// GIVEN
		// The test unit has been initialized with a small maxPartSize of 10 bytes
		testUnit = FileWriter(name: defaultName, fileExtension: defaultFileExtension, directory: tmpDirectory, maxPartSize: 10)
		
		// WHEN
		// The test units write to lines each of 6 bytes + new line character
		try testUnit.writeLine(data: "Test 1".data(using: .utf8)!)
		try testUnit.writeLine(data: "Test 2".data(using: .utf8)!)
		
		// THEN
		// The test unit should return two urls on finish calls
		let urls = try testUnit.finish()
		
		let expectedFileURLPart1 = tmpDirectory.appendingPathComponent("Test-0.txt")
		let expectedFileURLPart2 = tmpDirectory.appendingPathComponent("Test-1.txt")
		XCTAssertEqual(urls, [expectedFileURLPart1, expectedFileURLPart2])
		
		let fileContentPart1 = try String(contentsOf: expectedFileURLPart1, encoding: .utf8)
		let fileContentPart2 = try String(contentsOf: expectedFileURLPart2, encoding: .utf8)
		
		XCTAssertEqual(fileContentPart1, "Test 1")
		XCTAssertEqual(fileContentPart2, "Test 2")
	}
}
