//
//  QuickAuthDatasourceProtocol.swift
//  QuickAuth
//
//  Created by Mirsad Arslanovic on 1/27/24.
//

import Foundation

public protocol QuickAuthDatasourceProtocol: AnyObject {
    func getReauthRequest() throws -> Request
    func getTokenService() -> any QuickAuthAccessServiceProtocol
}
