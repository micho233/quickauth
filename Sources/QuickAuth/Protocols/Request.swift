//
//  Request.swift
//  QuickAuth
//
//  Created by Mirsad Arslanovic on 1/27/24.
//

import Foundation

public typealias HTTPHeaders = [String: String]
public typealias QueryParameters = [String: String]

public enum HTTPMethod: String {
    case delete = "DELETE"
    case get = "GET"
    case patch = "PATCH"
    case post = "POST"
    case put = "PUT"
    case update = "UPDATE"
}

public enum ContentType: String {
    case json = "application/json"
    case formURLEncoded = "application/x-www-form-urlencoded"
    case formData = "multipart/form-data"
    case xml = "application/xml"
    case plainText = "text/plain"

    func value(boundary: String? = nil) -> String {
        switch self {
        case .formData where boundary != nil:
            return "\(self.rawValue); boundary=\(boundary!)"
        default:
            return self.rawValue
        }
    }

    var header: String {
        return "\(rawValue); charset=utf-8"
    }
}

public struct HTTPURLResponseError: Decodable, Error {
    private enum CodingKeys: String, CodingKey {
        case message
        case error
        case errorDescription = "error_description"
    }

    public var message: String?
    public var error: String?
    public var errorDescription: String?

    init(message: String? = nil,
         error: String? = nil,
         description: String? = nil) {
        self.message = message
        self.error = error
        self.errorDescription = description
    }

    init(status: HTTPURLResponseStatus) {
        self.message = status.rawValue
    }
}

enum HTTPURLResponseStatus: String {
    case badRequest = "Bad request"
    case failed = "Network request failed."
    case redirect = "This request has been redirected."
    case success = "Success"
    case unableToDecode = "We could not decode the response."
    case unauthorized = "You need to be authenticated first."
}

enum RequestError: String, Error {
    case invalidParameters = "Invalid parameters"
    case invalidURL = "Invalid url"
}

public protocol Request {
    var host: String { get }
    var path: String { get }
    var headers: HTTPHeaders? { get }
    var method: HTTPMethod { get }
    var parameters: QueryParameters? { get }
    var body: BodyEncoder? { get }
    var contentType: ContentType { get }
    var authorized: Bool { get }
    var download: Bool { get }
}

public extension Request {
    var contentType: ContentType {
        return .json
    }
}

public extension Request {
    var urlString: String { "\(host)\(path)" }
    var url: URL? { URL(string: urlString) }
    var headers: HTTPHeaders? { nil }
    var download: Bool { false }
}

public struct BodyEncoder {
    let data: Data?

    public init<T: Encodable>(value: T) {
        data = try? JSONEncoder().encode(value)
    }

    func properties() -> [String: Any] {
        guard let bodyData = data else { return [:] }
        return (try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any]) ?? [:]
    }

    func formData(boundary: String) -> Data {
        let parameters = properties()
        var body = Data()

        for (key, value) in parameters {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        body.append("--\(boundary)--\r\n")
        return body
    }
}

extension Request {
    func getRequest(token: (any QuickAuthAccessProtocol)? = nil) throws -> URLRequest {
        guard let requestURL = url else {
            throw RequestError.invalidURL
        }
        guard var components = URLComponents(url: requestURL,
                                             resolvingAgainstBaseURL: false) else {
            throw RequestError.invalidURL
        }

        let existingItems: [URLQueryItem] = components.queryItems ?? []
        var urlParameters: [URLQueryItem] = parameters?.map {
            URLQueryItem(name: String($0), value: String($1))
        } ?? []
        urlParameters.append(contentsOf: existingItems)

        if !urlParameters.isEmpty {
            components.queryItems = urlParameters
        }
        guard let url = components.url else {
            throw RequestError.invalidParameters
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = method.rawValue

        if download == false {
            request.addValue("application/json",
                             forHTTPHeaderField: "Accept")
            if contentType != .formData {
                request.addValue(contentType.header,
                                 forHTTPHeaderField: "Content-Type")
            }
        }

        if let token, authorized {
            request.addValue("Bearer".space.appending(token.accessToken),
                             forHTTPHeaderField: "Authorization")
        }

        headers?.forEach {
            request.addValue($0.value, forHTTPHeaderField: $0.key)
        }

        if method != .get {
            if contentType == .formData {
                let boundary = "Boundary-\(UUID().uuidString)"
                request.addValue(contentType.value(boundary: boundary), forHTTPHeaderField: "Content-Type")
                request.httpBody = body?.formData(boundary: boundary)
            } else {
                request.httpBody = body?.data
            }
        }

        return request
    }
}
