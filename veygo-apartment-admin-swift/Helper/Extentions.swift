//
//  Extentions.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 7/7/25.
//

import Foundation
import SwiftUI
internal import Combine

extension Array where Element: Identifiable, Element.ID == Int {
    func getItemBy(id: Int) -> Element? {
        return self.first { $0.id == id }
    }
}

extension DoNotRentList {
    func isValid() -> Bool {
        if let expUnwrapped = self.exp {
            let expDate = dateFromYYYYMMDD(expUnwrapped)!
            let now = Date()
            if expDate < now {
                return false
            } else {
                return true
            }
        } else {
            return true
        }
    }
}

extension PublishRenter {
    func emailIsValid() -> Bool {
        if let expUnwrapped = self.studentEmailExpiration {
            let expDate = dateFromYYYYMMDD(expUnwrapped)!
            let now = Date()
            if expDate < now {
                return false
            } else {
                return true
            }
        } else {
            return false
        }
    }
}

protocol HasName {
    var name: String { get }
}

class AdminSession: ObservableObject {
    @Published var user: PublishRenter? = nil
    
    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0
    
    // 用 token 和 user_id 调用后端 API 验证并查找用户信息 对了—>200, 不对—>re-login
    func validateTokenAndFetchUser() async throws {
        if token.isEmpty || userId == 0 {
            throw URLError(.userAuthenticationRequired)
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            APIQueueManager.shared.enqueueAPICall { token, userId, completion in
                let request = veygoCurlRequest(url: "/api/v1/admin/retrieve", method: "GET", headers: ["auth": "\(token)$\(userId)"])
                Task {
                    do {
                        let (data, response) = try await URLSession.shared.data(for: request)
                        guard let httpResponse = response as? HTTPURLResponse,
                              httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                            print("Invalid or unauthorized response")
                            await MainActor.run {
                                self.user = nil
                                APIQueueManager.shared.setAuth(userId: 0, token: "")
                            }
                            completion(nil)
                            continuation.resume(throwing: URLError(.badServerResponse))
                            return
                        }
                        if httpResponse.statusCode == 401 {
                            print("Unauthorized: 401")
                            await MainActor.run {
                                self.user = nil
                                APIQueueManager.shared.setAuth(userId: 0, token: "")
                            }
                            completion(nil)
                            continuation.resume(throwing: URLError(.userAuthenticationRequired))
                            return
                        }
                        guard httpResponse.statusCode == 200 else {
                            print("Invalid or unauthorized response")
                            await MainActor.run {
                                self.user = nil
                                APIQueueManager.shared.setAuth(userId: 0, token: "")
                            }
                            completion(nil)
                            continuation.resume(throwing: URLError(.badServerResponse))
                            return
                        }
                        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let renter = json["admin"],
                              let renterData = try? JSONSerialization.data(withJSONObject: renter),
                              let decodedUser = try? VeygoJsonStandard.shared.decoder.decode(PublishRenter.self, from: renterData) else {
                            print("Failed to parse user from response")
                            await MainActor.run {
                                self.user = nil
                                APIQueueManager.shared.setAuth(userId: 0, token: "")
                            }
                            completion(nil)
                            continuation.resume(throwing: DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Could not decode admin user")))
                            return
                        }
                        let newToken = httpResponse.value(forHTTPHeaderField: "token") ?? ""
                        await MainActor.run {
                            self.user = decodedUser
                            self.token = newToken
                            self.userId = decodedUser.id
                            print("New token refreshed.")
                            print("User loaded via token: \(decodedUser.name)")
                        }
                        completion(newToken)
                        continuation.resume()
                    } catch {
                        await MainActor.run {
                            self.user = nil
                            APIQueueManager.shared.setAuth(userId: 0, token: "")
                        }
                        completion(nil)
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}
