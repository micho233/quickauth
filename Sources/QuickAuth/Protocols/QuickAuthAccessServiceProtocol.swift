//
//  QuickAuthAccessServiceProtocol.swift
//  QuickAuth
//
//  Created by Mirsad Arslanovic on 1/27/24.
//

import Foundation

public protocol QuickAuthAccessServiceProtocol {
    func decode(data: Data) throws -> any QuickAuthAccessProtocol
    func save(token: any QuickAuthAccessProtocol) throws
    func getToken() throws -> QuickAuthAccessProtocol
    func deleteToken() throws
}
