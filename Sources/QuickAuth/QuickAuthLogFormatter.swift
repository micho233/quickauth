//
//  QuickAuthLogFormatter.swift
//  QuickAuth
//
//  Created by Mirsad Arslanovic on 1/27/24.
//

import Foundation

internal class QuickAuthLogFormatter {
    typealias NetworkResponse = (data: Data, response: URLResponse)

    public var allowUTF8Emoji = true

    let statusIcons = [1: "ℹ️",
                       2: "✅",
                       3: "⤴️",
                       4: "⛔️",
                       5: "❌"]

    let statusStrings = [// 1xx (Informational)
        100: "Continue",
        101: "Switching Protocols",
        102: "Processing",

        // 2xx (Success)
        200: "OK",
        201: "Created",
        202: "Accepted",
        203: "Non-Authoritative Information",
        204: "No Content",
        205: "Reset Content",
        206: "Partial Content",
        207: "Multi-Status",
        208: "Already Reported",
        226: "IM Used",

        // 3xx (Redirection)
        300: "Multiple Choices",
        301: "Moved Permanently",
        302: "Found",
        303: "See Other",
        304: "Not Modified",
        305: "Use Proxy",
        306: "Switch Proxy",
        307: "Temporary Redirect",
        308: "Permanent Redirect",

        // 4xx (Client Error)
        400: "Bad Request",
        401: "Unauthorized",
        402: "Payment Required",
        403: "Forbidden",
        404: "Not Found",
        405: "Method Not Allowed",
        406: "Not Acceptable",
        407: "Proxy Authentication Required",
        408: "Request Timeout",
        409: "Conflict",
        410: "Gone",
        411: "Length Required",
        412: "Precondition Failed",
        413: "Request Entity Too Large",
        414: "Request-URI Too Long",
        415: "Unsupported Media Type",
        416: "Requested Range Not Satisfiable",
        417: "Expectation Failed",
        418: "I'm a teapot",
        420: "Enhance Your Calm",
        422: "Unprocessable Entity",
        423: "Locked",
        424: "Method Failure",
        425: "Unordered Collection",
        426: "Upgrade Required",
        428: "Precondition Required",
        429: "Too Many Requests",
        431: "Request Header Fields Too Large",
        451: "Unavailable For Legal Reasons",

        // 5xx (Server Error)
        500: "Internal Server Error",
        501: "Not Implemented",
        502: "Bad Gateway",
        503: "Service Unavailable",
        504: "Gateway Timeout",
        505: "HTTP Version Not Supported",
        506: "Variant Also Negotiates",
        507: "Insufficient Storage",
        508: "Loop Detected",
        509: "Bandwidth Limit Exceeded",
        510: "Not Extended",
        511: "Network Authentication Required"]

    public func formatError(_ request: URLRequest, error: NSError) -> String {
        var message = ""

        if allowUTF8Emoji {
            message += "⚠️ "
        }

        if let method = request.httpMethod {
            message += "\(method) "
        }

        if let url = request.url?.absoluteString {
            message += "\(url) "
        }

        if let headers = request.allHTTPHeaderFields, headers.count > 0 {
            message += "\n" + formatHeaders(headers as [String: AnyObject])
        }

        message += "\nBody: \(formatBody(request.httpBody))"

        message += "\nERROR: \(error.localizedDescription)"

        if let reason = error.localizedFailureReason {
            message += "\nReason: \(reason)"
        }

        if let suggestion = error.localizedRecoverySuggestion {
            message += "\nSuggestion: \(suggestion)"
        }

        return message
    }

    public func formatRequest(_ request: URLRequest) -> String {
        var message = ""

        if allowUTF8Emoji {
            message += "⬆️ "
        }

        if let method = request.httpMethod {
            message += "\(method) "
        }

        if let url = request.url?.absoluteString {
            message += "'\(url)' "
        }

        if let headers = request.allHTTPHeaderFields, headers.count > 0 {
            message += "\n" + formatHeaders(headers as [String: AnyObject])
        }

        message += "\nBody: \(formatBody(request.httpBody))"

        return message
    }

    public func formatResponse(_ response: NetworkResponse, for request: URLRequest) -> String {
        var message = ""

        if allowUTF8Emoji {
            message += "⬇️ "
        }

        if let method = request.httpMethod {
            message += "\(method) "
        }

        if let url = response.response.url?.absoluteString {
            message += "'\(url)' "
        }

        if let httpResponse = response.response as? HTTPURLResponse {
            message += "("
            if allowUTF8Emoji {
                let iconNumber = Int(floor(Double(httpResponse.statusCode) / 100.0))
                if let iconString = statusIcons[iconNumber] {
                    message += "\(iconString) "
                }
            }

            message += "\(httpResponse.statusCode)"
            if let statusString = statusStrings[httpResponse.statusCode] {
                message += " \(statusString)"
            }
            message += ")"
        }

        if let headers = (response.response as? HTTPURLResponse)?.allHeaderFields as? [String: AnyObject],
           headers.count > 0 {
            message += "\n" + formatHeaders(headers)
        }

        message += "\nBody: \(formatBody(response.data))"

        return message
    }

    public func formatHeaders(_ headers: [String: AnyObject]) -> String {
        var message = "Headers: [\n"
        for (key, value) in headers {
            message += "\t\(key) : \(value)\n"
        }
        message += "]"
        return message
    }

    public func formatBody(_ body: Data?) -> String {
        if let body = body {
            if let json = try? JSONSerialization.jsonObject(with: body, options: .mutableContainers),
               let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let string = String(data: pretty, encoding: String.Encoding.utf8) {
                return string
            } else if let string = String(data: body, encoding: String.Encoding.utf8) {
                return string
            } else {
                return body.description
            }
        } else {
            return "nil"
        }
    }
}
