//
//  StringExtension.swift
//  QuickAuth
//
//  Created by Mirsad Arslanovic on 1/27/24.
//

import Foundation

extension String {
    var space: String {
        [self, " "].joined()
    }

    var decimal: Decimal {
        Decimal(string: digits) ?? 0
    }
}

extension StringProtocol where Self: RangeReplaceableCollection {
    var digits: Self {
        filter(\.isWholeNumber)
    }
}

extension LosslessStringConvertible {
    var string: String {
        .init(self)
    }
}
