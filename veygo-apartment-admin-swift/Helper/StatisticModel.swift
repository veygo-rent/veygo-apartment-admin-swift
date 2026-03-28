//
//  StatisticModel.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 3/27/26.
//

import Foundation

struct RentersStats: Decodable {
    let total: Int
    let active: Int
    let activePaid: Int
    let pendingDlApprovals: Int
    let pendingLeaseApprovals: Int
    let pendingInsuranceApprovals: Int
}
