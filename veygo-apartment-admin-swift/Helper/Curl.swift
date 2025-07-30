//
//  Curl.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/7/25.
//

import Foundation

nonisolated public func veygoCurlRequest (url: String, method: String, headers: [String: String] = [:], body: Data? = nil) -> URLRequest {
    let BASE_PATH = "https://dev.veygo.rent"
    guard let fullURL = URL(string: "\(BASE_PATH)\(url)") else {
        fatalError("Invalid URL: \(BASE_PATH)\(url)")
    }

    var request = URLRequest(url: fullURL)
    request.httpMethod = method
    request.allHTTPHeaderFields = headers
    request.httpBody = body
    
    if headers["Content-Type"] == nil && method != "GET" {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    
    request.setValue("none", forHTTPHeaderField: "Debug-Mode")
    #if DEBUG
    request.setValue("ios", forHTTPHeaderField: "Debug-Mode")
    #endif

    return request
}

struct VeygoJsonStandard {
    nonisolated static let shared = VeygoJsonStandard()
    nonisolated let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
    nonisolated let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }()
}

nonisolated public func extractToken(from response: URLResponse?) -> String? {
    guard let httpResponse = response as? HTTPURLResponse else {
        print("Failed to cast response to HTTPURLResponse")
        return nil
    }
    let token = httpResponse.value(forHTTPHeaderField: "token")
    print("Extracted token from header: \(token ?? "nil")")
    return token
}
