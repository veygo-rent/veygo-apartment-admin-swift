//
//  Curl.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/7/25.
//

import Foundation

public enum RequestMethods: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

nonisolated public func veygoCurlRequest (url: String, method: RequestMethods, headers: [String: String] = [:], body: Data? = nil, timeout: TimeInterval = 10.0) -> URLRequest {
    let BASE_PATH = "https://dev.veygo.rent"
    guard let fullURL = URL(string: "\(BASE_PATH)\(url)") else {
        fatalError("Invalid URL: \(BASE_PATH)\(url)")
    }

    var request = URLRequest(url: fullURL)
    request.timeoutInterval = timeout
    request.httpMethod = method.rawValue
    request.allHTTPHeaderFields = headers
    request.httpBody = body
    
    request.assumesHTTP3Capable = true
    
    let uuid = UUID().uuidString
    request.setValue(uuid, forHTTPHeaderField: "Request-ID")
    
    if headers["Content-Type"] == nil && method != .get {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    
    request.setValue("none", forHTTPHeaderField: "Debug-Mode")
    #if DEBUG
    request.setValue("ios", forHTTPHeaderField: "Debug-Mode")
    #endif

    return request
}

nonisolated public func extractToken(from response: URLResponse?, for purpose: String) -> String? {
    guard let httpResponse = response as? HTTPURLResponse else {
        print("Failed to cast response to HTTPURLResponse")
        return nil
    }
    let token = httpResponse.value(forHTTPHeaderField: "token")
    print("Extracted token from header: \(token ?? "nil") for \(purpose)\n")
    return token
}
