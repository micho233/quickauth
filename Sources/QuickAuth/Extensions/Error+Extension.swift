//
//  Error+Extension.swift
//  QuickAuth
//
//  Created by Mirsad Arslanovic on 3/19/24.
//

import Foundation

extension Error {
    var nsError: NSError {
        return self as NSError
    }

    var networkError: NetworkError? {
        return self as? NetworkError
    }

    var isNoInternetConnectionError: Bool {
        switch nsError.code {
        case URLError.Code.timedOut.rawValue,
             URLError.Code.notConnectedToInternet.rawValue,
             URLError.Code.networkConnectionLost.rawValue,
             URLError.Code.secureConnectionFailed.rawValue,
             URLError.Code.cannotFindHost.rawValue,
             URLError.Code.cancelled.rawValue,
             URLError.Code.resourceUnavailable.rawValue,
             URLError.Code.dataNotAllowed.rawValue,
             URLError.Code.cannotConnectToHost.rawValue,
             URLError.Code.internationalRoamingOff.rawValue,
             URLError.Code.callIsActive.rawValue:
            return true
        default:
            return false
        }
    }
}
