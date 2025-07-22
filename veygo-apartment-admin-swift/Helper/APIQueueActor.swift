import Foundation

@globalActor
struct APIQueueActor {
    static let shared = APIQueueActorType()
    actor APIQueueActorType {}
}
