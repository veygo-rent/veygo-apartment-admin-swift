//
//  DateTime.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 7/8/25.
//

import Foundation

@BackgroundActor class VeygoDateStandard {
    static let shared = VeygoDateStandard()
    let YYYYMMDDformator: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    let standardDateFormator: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
