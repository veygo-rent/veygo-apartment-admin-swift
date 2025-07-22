import Foundation

class APIQueueManager {
    static let shared = APIQueueManager()
    private let queue = DispatchQueue(label: "com.veygo.apiQueue")
    private var isRequesting = false
    private var requestQueue: [(_ token: String, _ userId: Int, _ completion: @escaping (String?) -> Void) -> Void] = []
    
    private init() {}
    
    // Helper for token
    private var token: String {
        get { UserDefaults.standard.string(forKey: "token") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "token") }
    }
    // Helper for userId
    private var userId: Int {
        get { UserDefaults.standard.integer(forKey: "user_id") }
        set { UserDefaults.standard.set(newValue, forKey: "user_id") }
    }
    
    // Set userId and token (e.g., after login)
    func setAuth(userId: Int, token: String) {
        queue.sync {
            self.userId = userId
            self.token = token
        }
    }
    
    // Enqueue an API call
    func enqueueAPICall(_ apiCall: @escaping (_ token: String, _ userId: Int, _ completion: @escaping (String?) -> Void) -> Void) {
        queue.async {
            self.requestQueue.append(apiCall)
            self.processNext()
        }
    }
    
    private func processNext() {
        guard !isRequesting, !requestQueue.isEmpty else { return }
        isRequesting = true
        let apiCall = requestQueue.removeFirst()
        let token = self.token
        let userId = self.userId
        apiCall(token, userId) { [weak self] newToken in
            guard let self = self else { return }
            self.queue.async {
                if let newToken = newToken, !newToken.isEmpty, newToken != self.token {
                    self.token = newToken
                } else {
                    self.token = ""
                    self.userId = 0
                }
                self.isRequesting = false
                self.processNext()
            }
        }
    }
}

// Usage Example:
// APIQueueManager.shared.enqueueAPICall { token, userId, completion in
//     // Perform your API call here, using token and userId
//     // On response, call completion(newToken)
// } 
