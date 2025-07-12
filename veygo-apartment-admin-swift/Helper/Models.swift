//
//  Models.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/7/25.
//

import Foundation

enum VerificationType: String, Codable {
    case email = "Email"
    case phone = "Phone"
}

enum AgreementStatus: String, Codable {
    case rental = "Rental"
    case void = "Void"
    case canceled = "Canceled"
}

enum EmployeeTier: String, Codable {
    case user = "User"
    case generalEmployee = "GeneralEmployee"
    case maintenance = "Maintenance"
    case admin = "Admin"
}

enum PaymentType: String, Codable {
    case canceled = "canceled"
    case processing = "processing"
    case requiresAction = "requires_action"
    case requiresCapture = "requires_capture"
    case requiresConfirmation = "requires_confirmation"
    case requiresPaymentMethod = "requires_payment_method"
    case succeeded = "succeeded"
}

enum PlanTier: String, Codable {
    case free = "Free"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"
}

enum Gender: String, Codable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    case pnts = "PNTS"
}

enum TransactionType: String, Codable {
    case credit = "Credit"
    case cash = "Cash"
}

struct PublishRenter: Identifiable, Equatable, Codable {
    var id: Int
    var name: String
    var studentEmail: String
    var studentEmailExpiration: String?
    var phone: String
    var phoneIsVerified: Bool
    var dateOfBirth: String
    var profilePicture: String?
    var gender: Gender?
    var dateOfRegistration: Date
    var driversLicenseNumber: String?
    var driversLicenseStateRegion: String?
    var driversLicenseExpiration: String? // Admin needs to verify
    var insuranceLiabilityExpiration: String? // Admin needs to verify
    var insuranceCollisionExpiration: String? // Admin needs to verify
    var apartmentId: Int
    var leaseAgreementExpiration: String? // Admin needs to verify
    var billingAddress: String?
    var signatureDatetime: Date?
    var planTier: PlanTier
    var planRenewalDay: String
    var planExpireMonthYear: String
    var planAvailableDuration: Double
    var isPlanAnnual: Bool
    var employeeTier: EmployeeTier
    var subscriptionPaymentMethodId: Int?
}

struct DoNotRentList: Identifiable, Equatable, Codable {
    var id: Int
    var name: String?
    var email: String?
    var phone: String?
    var note: String
    var exp: String?
}


struct Apartment: Identifiable, Equatable, Codable, HasName {
    var id: Int
    var name: String
    var email: String
    var phone: String
    var address: String
    var acceptedSchoolEmailDomain: String
    var freeTierHours: Double
    var freeTierRate: Double
    var silverTierHours: Double
    var silverTierRate: Double
    var goldTierHours: Double
    var goldTierRate: Double
    var platinumTierHours: Double
    var platinumTierRate: Double
    var durationRate: Double
    var liabilityProtectionRate: Double
    var pcdwProtectionRate: Double
    var pcdwExtProtectionRate: Double
    var rsaProtectionRate: Double
    var paiProtectionRate: Double
    var isOperating: Bool
    var isPublic: Bool
    var uniId: Int
    var taxes: [Int?]
}

struct Tax: Identifiable, Equatable, Codable, HasName {
    var id: Int
    var name: String
    var multiplier: Double
    var isEffective: Bool
}

struct TransponderCompany: Identifiable, Equatable, Codable {
    var id: Int
    var name: String
    var correspondingKeyForVehicleId: String
    var correspondingKeyForTransactionName: String
    var customPrefixForTransactionName: String
    var correspondingKeyForTransactionTime: String
    var correspondingKeyForTransactionAmount: String
    var timestampFormat: String
    var timezone: String?
}
