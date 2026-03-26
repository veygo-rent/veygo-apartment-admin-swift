//
//  Standards.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 8/11/25.
//

import Foundation

struct VeygoDatetimeStandard {
    nonisolated static let shared = VeygoDatetimeStandard()
    nonisolated let yyyyMMddDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    nonisolated let usStandardDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/dd/yyyy"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    
    func formattedDateTime(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today, " + timeFormatter.string(from: date)
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow, " + timeFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday, " + timeFormatter.string(from: date)
        } else {
            return fullDateFormatter.string(from: date)
        }
    }

    private var timeFormatter: DateFormatter {
        let df = DateFormatter()
        df.timeStyle = .short       // "6:10 PM"
        return df
    }

    private var fullDateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "MMM d, h:mm a"
        return df
    }
    
    func mediumLengthDateString(from date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: date)
    }
}

struct VeygoJsonStandard {
    nonisolated static let shared = VeygoJsonStandard()
    nonisolated let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
    nonisolated let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }()
}

struct VeygoCurrencyStandard {
    nonisolated static let shared = VeygoCurrencyStandard()
    nonisolated let dollarFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    nonisolated let centFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_US_POSIX")
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        f.multiplier = 100
        f.positiveSuffix = "¢"
        f.negativeSuffix = "¢"
        return f
    }()
}

struct VeygoPricingStandard {
    let apartment: Apartment
    let vehicle: PublishRenterVehicle
    
    func standardMileageRate() -> Decimal {
        if let overwrite = apartment.mileageRateOverwrite {
            return overwrite.value
        } else {
            return vehicle.msrpFactor.value * apartment.durationRate.value * apartment.mileageConversion.value
        }
    }

    func perMileSubtitle() -> String {
        let cents = VeygoCurrencyStandard.shared.centFormatter.string(from: standardMileageRate() as NSDecimalNumber)!
        return "\(cents) per mile afterwards"
    }

    func mileagePackagePrice(for pkg: MileagePackage) -> Decimal {
        let baseRate: Decimal
        if let overwrite = apartment.mileagePackageOverwrite {
            baseRate = overwrite.value
        } else {
            baseRate = vehicle.msrpFactor.value * apartment.durationRate.value * apartment.mileageConversion.value
        }
        return baseRate * Decimal(pkg.miles) * (Decimal(pkg.discountedRate) / 100.0)
    }
    
    func calculateBillableDurationHours(rawDuration: TimeInterval) -> Decimal {
        // Tiered billing:
        // - First 8 hours are billed 1:1
        // - Hours after 8 up to the end of the first week (168 hours total) are billed at 0.25 per hour
        // - Hours after 168 are billed at 0.15 per hour
        let billableDurationHours = Decimal(rawDuration) / Decimal(3600)

        if billableDurationHours <= Decimal(0) {
            return Decimal(0)
        }

        // Tier 1: first 8 hours at 1x
        let tier1Hours = min(billableDurationHours, Decimal(8))

        // Tier 2: from hour 9 up to hour 168 (next 160 hours) at 0.25x
        let tier2Raw = billableDurationHours - Decimal(8)
        let tier2Hours = max(Decimal(0), min(tier2Raw, Decimal(160)))

        // Tier 3: beyond 168 hours at 0.15x
        let tier3Hours = max(Decimal(0), billableDurationHours - Decimal(168))

        return tier1Hours
            + (tier2Hours * Decimal(string: "0.25")!)
            + (tier3Hours * Decimal(string: "0.15")!)
    }
    
    func calculateDurationAfterReward(rawDuration: TimeInterval, rewardHours: Decimal) -> TimeInterval {
        if rewardHours <= Decimal(0) {
            return rawDuration
        }

        // Subtract reward time safely (prevent negative billable duration due to rounding)
        let totalMinutes = max(Int64((rawDuration / 60.0).rounded(.down)), 0)
        let rewardMinutesDecimal = rewardHours * Decimal(60)
        var rewardMinutes = NSDecimalNumber(decimal: rewardMinutesDecimal).rounding(accordingToBehavior: nil).int64Value

        if rewardMinutes > totalMinutes {
            rewardMinutes = totalMinutes
        }

        return TimeInterval(totalMinutes - rewardMinutes) * 60.0
    }
    
    func billableDaysCount(rawDuration: TimeInterval) -> Int {
        // Billable days are based on the actual trip duration, not the discounted billable hours.
        let actualHours = Decimal(Int64((rawDuration / 60.0).rounded(.down))) / Decimal(60)
        return NSDecimalNumber(decimal: actualHours / Decimal(24)).rounding(accordingToBehavior: NSDecimalNumberHandler(
            roundingMode: .up,
            scale: 0,
            raiseOnExactness: false,
            raiseOnOverflow: true,
            raiseOnUnderflow: true,
            raiseOnDivideByZero: true
        )).intValue
    }

    func calculateLateHours(supposed: Date, actual: Date) -> Decimal {
        if supposed >= actual {
            return Decimal(0)
        } else {
            // Calculate the difference in hours
            let diffSeconds = actual.timeIntervalSince(supposed)
            let lateMinutes = Int64((diffSeconds / 60.0).rounded(.down))
            let lateHours = Decimal(lateMinutes) / Decimal(60)
            return lateHours
        }
    }
}
