import Foundation
@main
public struct OpenFoodFactsSmallGenerator {
    public private(set) var text = "Hello, World!"

    public static func main() async throws{
		let downloader = ProductDownloader(session: .shared, language: .english, downloadDirectory: FileManager.default.temporaryDirectory)
		do {
			try await downloader.start()
		} catch {
			print("Download failed with error: \(error)")
		}
		
    }
}
