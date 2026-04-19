//
//  DriversLicenseView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 3/28/26.
//

import SwiftUI
import UIKit
import PDFKit

struct DriversLicenseView: View {
    @EnvironmentObject private var session: AdminSession
    @Environment(\.dismiss) private var dismiss

    @State private var renter: PublishRenter?
    @State private var loadedImage: UIImage?
    @State private var loadedPdfData: Data?
    @State private var rotatedImageCache: [Int: UIImage] = [:]
    @State private var isLoading = false
    @State private var rotationQuarterTurns: Int = 0
    @State private var isSubmitting = false
    
    @State private var driversLicenseNumberInput: String = ""
    @State private var driversLicenseStateRegionInput: String = ""
    @State private var driversLicenseExpiration: Date = Date()
    @State private var driversLicenseExpirationInput: String = ""
    @State private var actionReasonInput: String = ""
    @State private var renterStreetAddressInput: String = ""
    @State private var renterExtendedAddressInput: String = ""
    @State private var renterCityInput: String = ""
    @State private var renterStateInput: String = ""
    @State private var renterZipcodeInput: String = ""
    @State private var selectedAction: VerifyAction = .approved

    @State private var showAlert: Bool = false
    @State private var toDismiss: Bool = false
    @State private var clearUserTriggered: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

    private let driversLicenseStateRegionMaxLength = 6
    
    private enum VerifyAction: Hashable {
        case declinePrimary
        case declineSecondary
        case requireSecondary
        case approved
    }
    
    private var availableActions: [VerifyAction] {
        guard let renter else { return [] }
        return renter.requiresSecondaryDriverLic
            ? [.declineSecondary, .approved]
            : [.declinePrimary, .requireSecondary, .approved]
    }
    
    private func actionTitle(_ action: VerifyAction) -> String {
        switch action {
        case .declinePrimary: return "Decline Primary"
        case .declineSecondary: return "Decline Secondary"
        case .requireSecondary: return "Require Secondary"
        case .approved: return "Approved"
        }
    }
    
    private var parsedDriversLicenseExpirationInput: Date? {
        let value = driversLicenseExpirationInput.trimmingCharacters(in: .whitespacesAndNewlines)
        return VeygoDatetimeStandard.shared.usStandardDateFormatter.date(from: value)
    }
    
    private var isDriversLicenseExpirationInputValid: Bool {
        let value = driversLicenseExpirationInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.count == 10 else { return false }
        guard let parsed = parsedDriversLicenseExpirationInput else { return false }
        return VeygoDatetimeStandard.shared.usStandardDateFormatter.string(from: parsed) == value
    }
    
    private func formattedUsDateInput(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        var formatted = ""
        for (index, char) in digits.enumerated() {
            if index == 2 || index == 4 {
                formatted.append("/")
            }
            if index >= 8 { break }
            formatted.append(char)
        }
        return formatted
    }
    
    private var displayedImage: UIImage? {
        guard let loadedImage else {
            return nil
        }
        let normalizedTurns = ((rotationQuarterTurns % 4) + 4) % 4
        return rotatedImageCache[normalizedTurns] ?? loadedImage.rotated(byQuarterTurns: normalizedTurns)
    }

    private var measuredDisplayFrame: CGSize? {
        guard let displayedImage else {
            return nil
        }
        let imageSize = displayedImage.size
        guard imageSize.width > 0, imageSize.height > 0 else {
            return nil
        }
        let maxDimension: CGFloat = 420
        let scale = min(1, maxDimension / imageSize.width, maxDimension / imageSize.height)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading {
                    LoadingView()
                        .frame(width: 320, height: 220)
                        .cornerRadius(12)
                } else if let loadedPdfData {
                    PDFDocumentContainerView(pdfData: loadedPdfData)
                        .frame(maxWidth: .infinity)
                        .frame(height: 560)
                        .padding()
                        .background(Color.cardBG)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if let displayedImage {
                    VStack {
                        Image(uiImage: displayedImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(6)
                            .animation(.easeInOut(duration: 0.2), value: rotationQuarterTurns)
                    }
                    .frame(
                        width: measuredDisplayFrame?.width ?? 320,
                        height: measuredDisplayFrame?.height ?? 220
                    )
                    .padding()
                    .background(Color.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    HStack(spacing: 16) {
                        SecondaryButton(text: "Rotate Left") {
                            rotationQuarterTurns -= 1
                        }
                        SecondaryButton(text: "Rotate Right") {
                            rotationQuarterTurns += 1
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No Driver's License",
                        systemImage: "doc.text.image",
                        description: Text("You are all caught up!")
                    )
                }
                
                if let renter {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(renter.name)
                            .font(.headline)
                        Text(renter.studentEmail)
                            .foregroundStyle(.secondary)
                        Text(renter.phone)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                if renter != nil {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Verification")
                            .font(.headline)
                        
                        Picker("Action", selection: $selectedAction) {
                            ForEach(availableActions, id: \.self) { action in
                                Text(actionTitle(action)).tag(action)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        if selectedAction == .declinePrimary || selectedAction == .declineSecondary {
                            TextInputField(placeholder: "Reason", text: $actionReasonInput)
                        }
                        
                        if selectedAction == .requireSecondary {
                            TextInputField(placeholder: "Reason", text: $actionReasonInput)
                            TextInputField(placeholder: "Driver's License Number (optional)", text: $driversLicenseNumberInput)
                            TextInputField(placeholder: "License State/Region (optional)", text: $driversLicenseStateRegionInput)
                        }
                        
                        if selectedAction == .approved {
                            TextInputField(placeholder: "Driver's License Number (optional)", text: $driversLicenseNumberInput)
                            TextInputField(placeholder: "License State/Region (optional)", text: $driversLicenseStateRegionInput)
                            TextInputField(placeholder: "License Expiration (MM/DD/YYYY)", text: $driversLicenseExpirationInput)
                            
                            TextInputField(placeholder: "Street Address", text: $renterStreetAddressInput)
                            TextInputField(placeholder: "Address 2 (optional)", text: $renterExtendedAddressInput)
                            TextInputField(placeholder: "City", text: $renterCityInput)
                            TextInputField(placeholder: "State", text: $renterStateInput)
                            TextInputField(placeholder: "Zipcode", text: $renterZipcodeInput)
                        }
                        
                        PrimaryButton(text: isSubmitting ? "Submitting..." : "Submit") {
                            submitVerification(selectedAction)
                        }
                        .disabled(selectedAction == .approved && !isDriversLicenseExpirationInputValid)
                    }
                    .disabled(isSubmitting || isLoading)
                    .padding()
                    .background(Color.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .scrollContentBackground(.hidden)
        .background(Color.mainBG)
        .navigationTitle("Approve Driver's License")
        .navigationBarTitleDisplayMode(.large)
        .scrollIndicators(.hidden)
        .onAppear {
            requestNextRenter()
        }
        .onChange(of: driversLicenseStateRegionInput) { _, newValue in
            if newValue.count > driversLicenseStateRegionMaxLength {
                driversLicenseStateRegionInput = String(newValue.prefix(driversLicenseStateRegionMaxLength))
            }
        }
        .onChange(of: driversLicenseExpirationInput) { _, newValue in
            let formatted = formattedUsDateInput(newValue)
            if formatted != newValue {
                driversLicenseExpirationInput = formatted
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if clearUserTriggered {
                    session.user = nil
                }
                if toDismiss {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

    private func requestNextRenter() {
        guard !isLoading else { return }
        isLoading = true
        Task {
            await ApiCallActor.shared.appendApi { token, userId in
                await loadNextRenterNeedDlVerifyAsync(token, userId)
            }
        }
    }
    
    private func submitVerification(_ action: VerifyAction) {
        guard !isSubmitting, !isLoading, let renter else { return }
        
        let trimmedReason = actionReasonInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if (action == .declinePrimary || action == .declineSecondary || action == .requireSecondary) && trimmedReason.isEmpty {
            alertTitle = "Reason Required"
            alertMessage = "Please provide a reason for this action."
            showAlert = true
            return
        }
        
        if action == .approved {
            guard let parsedExpiration = parsedDriversLicenseExpirationInput else {
                alertTitle = "Invalid Date"
                alertMessage = "Use MM/DD/YYYY for license expiration."
                showAlert = true
                return
            }
            driversLicenseExpiration = parsedExpiration
            
            let street = renterStreetAddressInput.trimmingCharacters(in: .whitespacesAndNewlines)
            let city = renterCityInput.trimmingCharacters(in: .whitespacesAndNewlines)
            let state = renterStateInput.trimmingCharacters(in: .whitespacesAndNewlines)
            let zipcode = renterZipcodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
            let extended = renterExtendedAddressInput.trimmingCharacters(in: .whitespacesAndNewlines)
            let hasAnyAddress = !street.isEmpty || !city.isEmpty || !state.isEmpty || !zipcode.isEmpty || !extended.isEmpty
            let hasAllRequiredAddress = !street.isEmpty && !city.isEmpty && !state.isEmpty && !zipcode.isEmpty
            if hasAnyAddress && !hasAllRequiredAddress {
                alertTitle = "Address Incomplete"
                alertMessage = "Provide street, city, state, and zipcode for renter address."
                showAlert = true
                return
            }
        }
        
        isSubmitting = true
        Task {
            await ApiCallActor.shared.appendApi { token, userId in
                await verifyDriversLicenseAsync(
                    token,
                    userId,
                    renterId: renter.id,
                    action: action
                )
            }
            await MainActor.run {
                isSubmitting = false
            }
        }
    }

    @ApiCallActor
    private func loadNextRenterNeedDlVerifyAsync(_ token: String, _ userId: Int) async -> ApiTaskResponse {
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        do {
            guard !token.isEmpty, userId > 0 else {
                await MainActor.run {
                    let decodedBody = ErrorResponse.E401
                    alertTitle = decodedBody.title
                    alertMessage = decodedBody.message
                    showAlert = true
                    clearUserTriggered = true
                }
                return .clearUser
            }

            let request = veygoCurlRequest(
                url: "/api/v1/admin/renter-need-verify",
                method: .get,
                headers: [
                    "auth": "\(token)$\(userId)",
                    "renter-type": "DriversLicense"
                ]
            )
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    let body = ErrorResponse.WRONG_PROTOCOL
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
                return .doNothing
            }

            switch httpResponse.statusCode {
            case 200:
                guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(RenterNeedVerify.self, from: data) else {
                    await MainActor.run {
                        let body = ErrorResponse.E_DEFAULT
                        alertTitle = body.title
                        alertMessage = body.message
                        showAlert = true
                    }
                    return .doNothing
                }
                await MainActor.run {
                    renter = decodedBody.renter
                    loadedImage = nil
                    loadedPdfData = nil
                    rotatedImageCache = [:]
                    rotationQuarterTurns = 0
                    selectedAction = decodedBody.renter.requiresSecondaryDriverLic ? .declineSecondary : .declinePrimary
                    actionReasonInput = ""
                    driversLicenseNumberInput = decodedBody.renter.driversLicenseNumber ?? ""
                    driversLicenseStateRegionInput = decodedBody.renter.driversLicenseStateRegion ?? ""
                    if let expiration = decodedBody.renter.driversLicenseExpiration,
                       let parsedDate = VeygoDatetimeStandard.shared.yyyyMMddDateFormatter.date(from: expiration) {
                        driversLicenseExpiration = parsedDate
                        driversLicenseExpirationInput = VeygoDatetimeStandard.shared.usStandardDateFormatter.string(from: parsedDate)
                    } else {
                        driversLicenseExpiration = Date()
                        driversLicenseExpirationInput = ""
                    }
                    renterStreetAddressInput = decodedBody.renter.billingAddress?.streetAddress ?? ""
                    renterExtendedAddressInput = decodedBody.renter.billingAddress?.extendedAddress ?? ""
                    renterCityInput = decodedBody.renter.billingAddress?.city ?? ""
                    renterStateInput = decodedBody.renter.billingAddress?.state ?? ""
                    renterZipcodeInput = decodedBody.renter.billingAddress?.zipcode ?? ""
                }
                if let imageURL = URL(string: decodedBody.fileLink.fileLink) {
                    await loadDocumentAsync(imageURL)
                }
                return .doNothing
            case 401:
                if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                        clearUserTriggered = true
                    }
                } else {
                    let decodedBody = ErrorResponse.E401
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                        clearUserTriggered = true
                    }
                }
                return .clearUser
            case 404:
                await MainActor.run {
                    alertTitle = "All Caught Up"
                    alertMessage = "All driver's licences are verified."
                    showAlert = true
                    toDismiss = true
                }
                return .doNothing
            default:
                let body = ErrorResponse.E_DEFAULT
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
                return .doNothing
            }
        } catch {
            await MainActor.run {
                let body = ErrorResponse.E_DEFAULT
                alertTitle = body.title
                alertMessage = body.message
                showAlert = true
            }
            return .doNothing
        }
    }
    
    @ApiCallActor
    private func verifyDriversLicenseAsync(
        _ token: String,
        _ userId: Int,
        renterId: Int,
        action: VerifyAction
    ) async -> ApiTaskResponse {
        do {
            guard !token.isEmpty, userId > 0 else {
                await MainActor.run {
                    let decodedBody = ErrorResponse.E401
                    alertTitle = decodedBody.title
                    alertMessage = decodedBody.message
                    showAlert = true
                    clearUserTriggered = true
                }
                return .clearUser
            }
            
            let requestBodyData: Data
            let inputSnapshot = await MainActor.run {
                (
                    number: driversLicenseNumberInput.trimmingCharacters(in: .whitespacesAndNewlines),
                    state: driversLicenseStateRegionInput.trimmingCharacters(in: .whitespacesAndNewlines),
                    reason: actionReasonInput.trimmingCharacters(in: .whitespacesAndNewlines),
                    expiration: driversLicenseExpiration,
                    street: renterStreetAddressInput.trimmingCharacters(in: .whitespacesAndNewlines),
                    extended: renterExtendedAddressInput.trimmingCharacters(in: .whitespacesAndNewlines),
                    city: renterCityInput.trimmingCharacters(in: .whitespacesAndNewlines),
                    stateAddress: renterStateInput.trimmingCharacters(in: .whitespacesAndNewlines),
                    zipcode: renterZipcodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            let number = inputSnapshot.number
            let state = inputSnapshot.state
            let reason = inputSnapshot.reason
            let optionalNumber: String? = number.isEmpty ? nil : number
            let optionalState: String? = state.isEmpty ? nil : state
            
            switch action {
            case .declinePrimary:
                struct DeclinePrimaryRequest: Encodable {
                    let type = "decline_primary"
                    let renterId: Int
                    let reason: String
                }
                requestBodyData = try VeygoJsonStandard.shared.encoder.encode(
                    DeclinePrimaryRequest(renterId: renterId, reason: reason)
                )
            case .declineSecondary:
                struct DeclineSecondaryRequest: Encodable {
                    let type = "decline_secondary"
                    let renterId: Int
                    let reason: String
                }
                requestBodyData = try VeygoJsonStandard.shared.encoder.encode(
                    DeclineSecondaryRequest(renterId: renterId, reason: reason)
                )
            case .requireSecondary:
                struct RequireSecondaryRequest: Encodable {
                    let type = "require_secondary"
                    let renterId: Int
                    let reason: String
                    let driversLicenseNumber: String?
                    let driversLicenseStateRegion: String?
                }
                requestBodyData = try VeygoJsonStandard.shared.encoder.encode(
                    RequireSecondaryRequest(
                        renterId: renterId,
                        reason: reason,
                        driversLicenseNumber: optionalNumber,
                        driversLicenseStateRegion: optionalState
                    )
                )
            case .approved:
                struct ApprovedRequest: Encodable {
                    let type = "approved"
                    let renterId: Int
                    let driversLicenseNumber: String?
                    let driversLicenseStateRegion: String?
                    let driversLicenseExpiration: String
                    let renterAddress: UsAddress?
                }
                let expiration = VeygoDatetimeStandard.shared.yyyyMMddDateFormatter.string(from: inputSnapshot.expiration)
                let hasAnyAddress = !inputSnapshot.street.isEmpty
                    || !inputSnapshot.extended.isEmpty
                    || !inputSnapshot.city.isEmpty
                    || !inputSnapshot.stateAddress.isEmpty
                    || !inputSnapshot.zipcode.isEmpty
                let billingAddress: UsAddress? = hasAnyAddress
                    ? UsAddress(
                        streetAddress: inputSnapshot.street,
                        extendedAddress: inputSnapshot.extended.isEmpty ? nil : inputSnapshot.extended,
                        city: inputSnapshot.city,
                        state: inputSnapshot.stateAddress,
                        zipcode: inputSnapshot.zipcode
                    )
                    : nil
                requestBodyData = try VeygoJsonStandard.shared.encoder.encode(
                    ApprovedRequest(
                        renterId: renterId,
                        driversLicenseNumber: optionalNumber,
                        driversLicenseStateRegion: optionalState,
                        driversLicenseExpiration: expiration,
                        renterAddress: billingAddress
                    )
                )
                if let JSONString = String(data: requestBodyData, encoding: String.Encoding.utf8) {
                   print(JSONString)
                }
            }
            
            let request = veygoCurlRequest(
                url: "/api/v1/admin/verify-drivers-license",
                method: .patch,
                headers: [
                    "auth": "\(token)$\(userId)",
                    "user-agent": "ios-admin-swift"
                ],
                body: requestBodyData
            )
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    let body = ErrorResponse.WRONG_PROTOCOL
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
                return .doNothing
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(RenterNeedVerify.self, from: data) else {
                    await MainActor.run {
                        let body = ErrorResponse.E_DEFAULT
                        alertTitle = body.title
                        alertMessage = body.message
                        showAlert = true
                    }
                    return .doNothing
                }
                await MainActor.run {
                    renter = decodedBody.renter
                    loadedImage = nil
                    loadedPdfData = nil
                    rotatedImageCache = [:]
                    rotationQuarterTurns = 0
                    selectedAction = decodedBody.renter.requiresSecondaryDriverLic ? .declineSecondary : .declinePrimary
                    actionReasonInput = ""
                    driversLicenseNumberInput = decodedBody.renter.driversLicenseNumber ?? ""
                    driversLicenseStateRegionInput = decodedBody.renter.driversLicenseStateRegion ?? ""
                    if let expiration = decodedBody.renter.driversLicenseExpiration,
                       let parsedDate = VeygoDatetimeStandard.shared.yyyyMMddDateFormatter.date(from: expiration) {
                        driversLicenseExpiration = parsedDate
                        driversLicenseExpirationInput = VeygoDatetimeStandard.shared.usStandardDateFormatter.string(from: parsedDate)
                    } else {
                        driversLicenseExpiration = Date()
                        driversLicenseExpirationInput = ""
                    }
                    renterStreetAddressInput = decodedBody.renter.billingAddress?.streetAddress ?? ""
                    renterExtendedAddressInput = decodedBody.renter.billingAddress?.extendedAddress ?? ""
                    renterCityInput = decodedBody.renter.billingAddress?.city ?? ""
                    renterStateInput = decodedBody.renter.billingAddress?.state ?? ""
                    renterZipcodeInput = decodedBody.renter.billingAddress?.zipcode ?? ""
                }
                if let fileURL = URL(string: decodedBody.fileLink.fileLink) {
                    await loadDocumentAsync(fileURL)
                }
                return .doNothing
            case 401:
                if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                        clearUserTriggered = true
                    }
                } else {
                    let decodedBody = ErrorResponse.E401
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                        clearUserTriggered = true
                    }
                }
                return .clearUser
            case 404:
                if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                        toDismiss = true
                    }
                } else {
                    let decodedBody = ErrorResponse.E404
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                        toDismiss = true
                    }
                }
                return .doNothing
            default:
                let body = ErrorResponse.E_DEFAULT
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
                return .doNothing
            }
        } catch {
            await MainActor.run {
                let body = ErrorResponse.E_DEFAULT
                alertTitle = body.title
                alertMessage = body.message
                showAlert = true
            }
            return .doNothing
        }
    }
    
    private func loadDocumentAsync(_ imageURL: URL) async {
        do {
            let (data, response) = try await URLSession.shared.data(from: imageURL)
            let mimeType = (response as? HTTPURLResponse)?
                .value(forHTTPHeaderField: "Content-Type")?
                .lowercased() ?? ""
            let isPdfByHeader = data.starts(with: [0x25, 0x50, 0x44, 0x46]) // "%PDF"
            let isPdf = mimeType.contains("pdf") || isPdfByHeader
            
            if isPdf {
                await MainActor.run {
                    loadedPdfData = data
                    loadedImage = nil
                    rotatedImageCache = [:]
                    rotationQuarterTurns = 0
                }
                return
            }
            
            if let image = UIImage(data: data) {
                let cache: [Int: UIImage] = [
                    0: image,
                    1: image.rotated(byQuarterTurns: 1),
                    2: image.rotated(byQuarterTurns: 2),
                    3: image.rotated(byQuarterTurns: 3)
                ]
                await MainActor.run {
                    loadedPdfData = nil
                    loadedImage = image
                    rotatedImageCache = cache
                }
                return
            }
            
            await MainActor.run {
                loadedPdfData = nil
                loadedImage = nil
                rotatedImageCache = [:]
                rotationQuarterTurns = 0
                alertTitle = "Unsupported Document"
                alertMessage = "This file is not a supported image or PDF."
                showAlert = true
            }
        } catch {
            // Keep placeholder when image cannot be loaded.
        }
    }
}

private struct PDFDocumentContainerView: UIViewRepresentable {
    let pdfData: Data
    
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .clear
        if let scrollView = view.subviews.compactMap({ $0 as? UIScrollView }).first {
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
        }
        view.document = PDFDocument(data: pdfData)
        return view
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(data: pdfData)
    }
}

private extension UIImage {
    func rotated(byQuarterTurns quarterTurns: Int) -> UIImage {
        let turns = ((quarterTurns % 4) + 4) % 4
        guard turns != 0 else { return self }

        var angle: CGFloat = 0
        switch turns {
        case 1:
            angle = .pi / 2
        case 2:
            angle = .pi
        default:
            angle = 3 * .pi / 2
        }

        let rotatedBounds = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: angle))
            .integral
        let newSize = CGSize(width: abs(rotatedBounds.width), height: abs(rotatedBounds.height))

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            let context = UIGraphicsGetCurrentContext()
            context?.translateBy(x: newSize.width / 2, y: newSize.height / 2)
            context?.rotate(by: angle)
            draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        }
    }
}
