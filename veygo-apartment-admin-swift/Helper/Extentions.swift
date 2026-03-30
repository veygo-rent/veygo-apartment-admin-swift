//
//  Extentions.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 7/7/25.
//

import Foundation
internal import Combine

extension Array where Element: Identifiable {
    func getItemBy(id: Element.ID) -> Element? {
        return self.first { $0.id == id }
    }
}

extension DoNotRentList {
    func isValid() -> Bool {
        if let expUnwrapped = self.exp {
            let expDate = VeygoDatetimeStandard.shared.yyyyMMddDateFormatter.date(from: expUnwrapped)!
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

extension PublishRenter {
    func emailIsValid() -> Bool {
        if let expUnwrapped = self.studentEmailExpiration {
            let expDate = VeygoDatetimeStandard.shared.yyyyMMddDateFormatter.date(from: expUnwrapped)!
            let now = Date()
            if expDate < now {
                return false
            } else {
                return true
            }
        } else {
            return false
        }
    }
}

protocol HasName {
    var name: String { get }
}

class AdminSession: ObservableObject {
    @Published var user: PublishRenter? = nil
}

extension Apartment {
    func localizedDate(for date: Date) -> String {
        let currentTimeZone = TimeZone.current
        let apartmentTimeZone = TimeZone(identifier: self.timezone) ?? currentTimeZone

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = apartmentTimeZone
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let formattedDate = dateFormatter.string(from: date)

        let currentAbbreviation = currentTimeZone.abbreviation(for: date)
        let apartmentAbbreviation = apartmentTimeZone.abbreviation(for: date)

        if apartmentAbbreviation != nil && apartmentAbbreviation != currentAbbreviation {
            return "\(formattedDate) \(apartmentAbbreviation!)"
        } else {
            return formattedDate
        }
    }
}

extension TripDetailedInfo {
    func localizedStartDate() -> String {
        let currentTimeZone = TimeZone.current
        let apartmentTimeZone = TimeZone(identifier: self.apartment.timezone) ?? currentTimeZone

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = apartmentTimeZone
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let pickupDate = self.agreement.rsvpPickupTime
        let formattedDate = dateFormatter.string(from: pickupDate)

        let currentAbbreviation = currentTimeZone.abbreviation(for: pickupDate)
        let apartmentAbbreviation = apartmentTimeZone.abbreviation(for: pickupDate)

        if apartmentAbbreviation != nil && apartmentAbbreviation != currentAbbreviation {
            return "\(formattedDate) \(apartmentAbbreviation!)"
        } else {
            return formattedDate
        }
    }
    func localizedEndDate() -> String {
        let currentTimeZone = TimeZone.current
        let apartmentTimeZone = TimeZone(identifier: self.apartment.timezone) ?? currentTimeZone

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = apartmentTimeZone
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let pickupDate = self.agreement.rsvpDropOffTime
        let formattedDate = dateFormatter.string(from: pickupDate)

        let currentAbbreviation = currentTimeZone.abbreviation(for: pickupDate)
        let apartmentAbbreviation = apartmentTimeZone.abbreviation(for: pickupDate)

        if apartmentAbbreviation != nil && apartmentAbbreviation != currentAbbreviation {
            return "\(formattedDate) \(apartmentAbbreviation!)"
        } else {
            return formattedDate
        }
    }
}

extension TripInfo {
    func localizedStartDate() -> String {
        let currentTimeZone = TimeZone.current
        let apartmentTimeZone = TimeZone(identifier: self.apartmentTimezone) ?? currentTimeZone

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = apartmentTimeZone
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let pickupDate = self.agreement.rsvpPickupTime
        let formattedDate = dateFormatter.string(from: pickupDate)

        let currentAbbreviation = currentTimeZone.abbreviation(for: pickupDate)
        let apartmentAbbreviation = apartmentTimeZone.abbreviation(for: pickupDate)

        if apartmentAbbreviation != nil && apartmentAbbreviation != currentAbbreviation {
            return "\(formattedDate) \(apartmentAbbreviation!)"
        } else {
            return formattedDate
        }
    }
}

struct SignupSession {
    var name: Optional<String> = nil
    var date_of_birth: Optional<String> = nil  // MM/DD/YYYY
    var phone: Optional<String> = nil
    var student_email: Optional<String> = nil
    var password: Optional<String> = nil
}

extension Date {
    /// Returns the next quarter-hour date after the current date.
    func nextQuarterHour() -> Date {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: self)
        let remainder = minute % 15
        let minutesToAdd = remainder == 0 ? 15 : 15 - remainder

        let dateWithoutSeconds = calendar.date(
            bySettingHour: calendar.component(.hour, from: self),
            minute: minute,
            second: 0,
            of: self
        )!

        return calendar.date(byAdding: .minute, value: minutesToAdd, to: dateWithoutSeconds)!
    }
}
