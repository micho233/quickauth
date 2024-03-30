//
//  NetworkError.swift
//  QuickAuth
//
//  Created by Mirsad Arslanovic on 1/27/24.
//

import Foundation

public enum NetworkError: String, Error {
    case noDataSource = "Datasource is not set"
    case selfNotFound = "Self not found"
    case refreshRequestNotFound = "Request for refresh token is not provided"
    case unauthorized = "User is not authorized"
    case noInternetConnection = "The Internet connection appears to be offline."
    case unitTesting = "Network request execution is not allowed for unit testing"
    case imageNotFound = "Image not found"
}
