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
        UserDefaults.standard.removeObject(forKey: "token")
        UserDefaults.standard.removeObject(forKey: "user_id")
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

    func addTask(
        using apiCall: @escaping @Sendable (_ token: String, _ userId: Int) async throws -> ApiTaskResponse
    ) {
        enqueue {
            do {
                let result = try await apiCall(self.token, self.userId)
                switch result {
                case .loginSuccessful(let id, let tok):
                    self.userId = id
                    self.token = tok
                    self.persistUserId(id)
                    self.persistToken(tok)
                case .renewSuccessful(let tok):
                    self.token = tok
                    self.persistToken(tok)
                case .clearUser:
                    self.token = ""
                    self.userId = 0
                    self.clearAppStorage()
                }
            } catch {
                print("Failed to process API task: \(error)")
            }
        }
    }

    func login(token: String, userId: Int) {
        self.token = token
        self.userId = userId
        persistToken(token)
        persistUserId(userId)
    }

    func clearCredentials() {
        self.token = ""
        self.userId = 0
        clearAppStorage()
    }
}
