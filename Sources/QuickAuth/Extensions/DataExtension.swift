//
//  DataExtension.swift
//  QuickAuth
//
//  Created by Mirsad Arslanovic on 2/6/24.
//

import Foundation

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }

    var prettyPrintedJSONString: String? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: jsonObject,
                                                     options: [.prettyPrinted]),
              let prettyJSON = String(data: data, encoding: .utf8) else {
            return nil
        }

        return prettyJSON
    }
}
