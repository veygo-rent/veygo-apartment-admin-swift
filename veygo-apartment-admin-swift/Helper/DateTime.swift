//
//  DateTime.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 7/8/25.
//

import Foundation

public func dateFromYYYYMMDD(_ raw: String) -> Date? {
    // Re-use the same formatter for every call
    struct Static {
        static let formatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            f.timeZone = TimeZone(secondsFromGMT: 0)
            f.locale = Locale(identifier: "en_US_POSIX")
            return f
        }()
    }
    
    return Static.formatter.date(from: raw)
}
