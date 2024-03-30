//
//  QuickAuthAccessProtocol.swift
//  QuickAuth
//
//  Created by Mirsad Arslanovic on 1/27/24.
//

import Foundation

public protocol QuickAuthAccessProtocol: Codable {
    var accessToken: String { get set }
    var refreshToken: String { get set }
    var createdDate: Date? { get set }
    var isExpired: Bool { get }
}

public extension QuickAuthAccessProtocol {
    mutating func setCreatedDate() {
        self.createdDate = Date()
    }
}
