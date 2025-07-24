import Foundation

@globalActor
struct BackgroundActor {
    static let shared = BackgroundActorType()
    actor BackgroundActorType {
        func run<T>(_ operation: @escaping @Sendable () async throws -> T) async rethrows -> T {
            try await operation()
        }
    }
}
