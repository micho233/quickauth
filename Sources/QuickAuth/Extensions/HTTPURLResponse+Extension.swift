//
//  HTTPURLResponse+Extension.swift
//  QuickAuth
//
//  Created by Mirsad Arslanovic on 1/27/24.
//

import Foundation

extension HTTPURLResponse {
    var status: HTTPURLResponseStatus {
        switch statusCode {
        case 200 ... 299: return .success
        case 300 ... 399: return .redirect
        case 401 ... 500: return .unauthorized
        case 400, 501 ... 599: return .badRequest
        default: return .failed
        }
    }
}
