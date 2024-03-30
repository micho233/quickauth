//
//  URLError+Extension.swift
//  QuickAuth
//
//  Created by Mirsad Arslanovic on 2/19/24.
//

import Foundation

extension URLError {
    var isNoInternetConnectionError: Bool {
        switch code {
        case .timedOut,
             .notConnectedToInternet,
             .networkConnectionLost,
             .secureConnectionFailed,
             .cannotFindHost,
             .cancelled,
             .resourceUnavailable,
             .dataNotAllowed,
             .cannotConnectToHost,
             .internationalRoamingOff,
             .callIsActive:
            return true
        default:
            return false
        }
    }
}
