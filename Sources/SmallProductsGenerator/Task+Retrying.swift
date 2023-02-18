import Foundation

extension Task where Failure == Error {
	@discardableResult
	static func retrying(
		priority: TaskPriority? = nil,
		maxRetryCount: Int = 10,
		operation: @Sendable @escaping () async throws -> Success
	) -> Task {
		Task(priority: priority) {
			let exponentialBackoffBase: UInt = 2
			let exponentialBackoffScale = 0.5
			for attempt in 0..<maxRetryCount {
				do {
					return try await operation()
				} catch {
					let jitter = Double.random(in: 0 ..< 0.5)
					let oneSecond = TimeInterval(1_000_000_000)
					let retryCount = attempt + 1
					let retryDelay = pow(Double(exponentialBackoffBase), Double(retryCount)) * exponentialBackoffScale + jitter
					let delay = UInt64(oneSecond * retryDelay)
					try await Task<Never, Never>.sleep(nanoseconds: delay)
					
					continue
				}
			}
			
			try Task<Never, Never>.checkCancellation()
			return try await operation()
		}
	}
}
