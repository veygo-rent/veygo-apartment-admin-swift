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
