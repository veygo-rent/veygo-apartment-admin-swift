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
    @MainActor func getItemBy(id: Int) -> Element? {
        return self.first { $0.id == id }
    }
}

extension PublishRenter {
    var emailIsValid: Bool {
        if let expUnwrapped = self.studentEmailExpiration {
            let expDate = VeygoDateStandard.shared.YYYYMMDDformator.date(from: expUnwrapped)!
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
    @BackgroundActor
    func validateTokenAndFetchUser() throws {
        Task {
            let token = await token
            let userId = await userId
            let authHeader = ["auth": "\(token)$\(userId)"]
            let request = veygoCurlRequest(url: "/api/v1/admin/retrieve", method: "GET", headers: authHeader)
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        self.user = nil
                        self.token = ""
                        self.userId = 0
                    }
                    throw URLError(.badServerResponse)
                }
                
                guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                    await MainActor.run {
                        self.user = nil
                        self.token = ""
                        self.userId = 0
                    }
                    throw URLError(.badServerResponse)
                }
                
                switch httpResponse.statusCode {
                case 200:
                    let newToken = httpResponse.value(forHTTPHeaderField: "token") ?? ""
                    let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let renter = responseJSON?["admin"],
                       let renterData = try? JSONSerialization.data(withJSONObject: renter),
                       let decodedUser = try? VeygoJsonStandard.shared.decoder.decode(PublishRenter.self, from: renterData) {
                        await MainActor.run {
                            self.user = decodedUser
                            self.token = newToken
                            self.userId = decodedUser.id
                        }
                    } else {
                        await MainActor.run {
                            self.user = nil
                            self.token = ""
                            self.userId = 0
                        }
                        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Could not decode admin user"))
                    }
                case 401:
                    await MainActor.run {
                        self.user = nil
                        self.token = ""
                        self.userId = 0
                    }
                    throw URLError(.userAuthenticationRequired)
                default:
                    await MainActor.run {
                        self.user = nil
                        self.token = ""
                        self.userId = 0
                    }
                    throw URLError(.badServerResponse)
                }
            } catch {
                await MainActor.run {
                    self.user = nil
                    self.token = ""
                    self.userId = 0
                }
                throw error
            }
        }
    }
}

