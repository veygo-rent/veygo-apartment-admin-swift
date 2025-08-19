//
//  Extentions.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 7/7/25.
//

import Foundation
internal import Combine
import UIKit

extension Array where Element: Identifiable {
    func getItemBy(id: Element.ID) -> Element? {
        return self.first { $0.id == id }
    }
    
    func getIndexBy(id: Element.ID) -> Int? {
        return self.firstIndex { $0.id == id }
    }
    
    mutating func updateItem(id: Element.ID, with newValue: Element) {
        if let index = self.getIndexBy(id: id) {
            self[index] = newValue
        }
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

extension UIViewController {
    func topMostPresented() -> UIViewController {
        if let nav = self as? UINavigationController { return nav.visibleViewController?.topMostPresented() ?? nav }
        if let tab = self as? UITabBarController { return tab.selectedViewController?.topMostPresented() ?? tab }
        if let presented = presentedViewController { return presented.topMostPresented() }
        return self
    }
}
