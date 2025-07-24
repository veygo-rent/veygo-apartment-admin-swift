//
//  ViewModels.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 7/23/25.
//

import Foundation

struct TaxViewModel: Identifiable, HasName {
    let id: Int
    let name: String
    let multiplier: Double
    let isEffective: Bool

    init(from tax: Tax) {
        self.id = tax.id
        self.name = tax.name
        self.multiplier = tax.multiplier
        self.isEffective = tax.isEffective
    }
}

struct TransponderCompanyViewModel: Identifiable, HasName {
    let id: Int
    let name: String
    let correspondingKeyForVehicleId: String
    let correspondingKeyForTransactionName: String
    let customPrefixForTransactionName: String
    let correspondingKeyForTransactionTime: String
    let correspondingKeyForTransactionAmount: String
    let timestampFormat: String
    let timezone: String?

    init(from company: TransponderCompany) {
        self.id = company.id
        self.name = company.name
        self.correspondingKeyForVehicleId = company.correspondingKeyForVehicleId
        self.correspondingKeyForTransactionName = company.correspondingKeyForTransactionName
        self.customPrefixForTransactionName = company.customPrefixForTransactionName
        self.correspondingKeyForTransactionTime = company.correspondingKeyForTransactionTime
        self.correspondingKeyForTransactionAmount = company.correspondingKeyForTransactionAmount
        self.timestampFormat = company.timestampFormat
        self.timezone = company.timezone
    }
}
