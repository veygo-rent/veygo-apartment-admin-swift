//
//  Extentions.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 7/7/25.
//

import Foundation

extension Array where Element == PublishRenter {
    func getRenterDetail(for renterID: Int) -> PublishRenter? {
        return self.first { $0.id == renterID }
    }
}

extension DoNotRentList {
    func isValid() -> Bool {
        if let expUnwrapped = self.exp {
            let expDate = dateFromYYYYMMDD(expUnwrapped)!
            let now = Date()
            if expDate < now {
                return false
            } else {
                return true
            }
        } else {
            return true
        }
    }
}
