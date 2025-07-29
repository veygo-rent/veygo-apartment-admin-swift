//
//  Actors.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 7/29/25.
//

import Foundation

enum ApiTaskResponse {
    case loginSuccessful(userId: Int, token: String)
    case renewSuccessful(token: String)
    case clearUser
    case doNothing
}

actor ApiCallManager {
    private var token: String = ""
    private var userId: Int = 0
    
    private var queue: [() async -> Void] = []
    private var isProcessingQueue = false
    
    private func persistToken(_ newToken: String) {
        UserDefaults.standard.set(newToken, forKey: "token")
    }
    
    private func persistUserId(_ userId: Int) {
        UserDefaults.standard.set(userId, forKey: "user_id")
    }
    
    private func clearAppStorage() {
        UserDefaults.standard.set(0, forKey: "token")
        UserDefaults.standard.set("", forKey: "user_id")
    }
    
    private func enqueue(_ operation: @escaping () async -> Void) {
        queue.append(operation)
        processQueueIfNeeded()
    }
    
    private func processQueueIfNeeded() {
        guard !isProcessingQueue, !queue.isEmpty else { return }
        
        isProcessingQueue = true
        
        Task {
            while !queue.isEmpty {
                let op = queue.removeFirst()
                await op()
            }
            isProcessingQueue = false
        }
    }
    
    func appendApi(
        task apiCall: @escaping @Sendable (_ token: String, _ userId: Int) async throws -> ApiTaskResponse
    ) {
        enqueue {
            do {
                let result = try await apiCall(self.token, self.userId)
                switch result {
                case .loginSuccessful(let id, let tok):
                    self.login(token: tok, userId: id)
                case .renewSuccessful(let tok):
                    self.token = tok
                    self.persistToken(tok)
                case .clearUser:
                    self.clearCredentials()
                case .doNothing:
                    break
                }
            } catch {
                print("Failed to process API task: \(error)")
            }
        }
    }
    
    private func login(token: String, userId: Int) {
        self.token = token
        self.userId = userId
        persistToken(token)
        persistUserId(userId)
    }
    
    private func clearCredentials() {
        self.token = ""
        self.userId = 0
        clearAppStorage()
    }
    
    init() {
        let defaults = UserDefaults.standard
        // Retrieve saved token or default to empty string
        self.token = defaults.string(forKey: "token") ?? ""
        // Retrieve saved userId or default to 0
        self.userId = defaults.integer(forKey: "user_id")
    }
}

@globalActor enum ApiCallActor {
    static let shared = ApiCallManager()
}
