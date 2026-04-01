//
//  InsuranceView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 4/1/26.
//

import SwiftUI
import UIKit
import PDFKit

struct InsuranceView: View {
    @EnvironmentObject private var session: AdminSession
    @Environment(\.dismiss) private var dismiss

    @State private var renter: PublishRenter?
    @State private var loadedImage: UIImage?
    @State private var loadedPdfData: Data?
    @State private var rotatedImageCache: [Int: UIImage] = [:]
    @State private var isLoading = false
    @State private var rotationQuarterTurns: Int = 0
    @State private var isSubmitting = false

    @State private var selectedAction: VerifyInsuranceAction = .declined
    @State private var actionReasonInput: String = ""
    @State private var insuranceLiabilityExpiration: Date = Date()
    @State private var insuranceCollisionValid: Bool = false

    @State private var showAlert: Bool = false
    @State private var toDismiss: Bool = false
    @State private var clearUserTriggered: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

    private enum VerifyInsuranceAction: Hashable {
        case declined
        case approved
    }

    private var displayedImage: UIImage? {
        guard let loadedImage else {
            return nil
        }
        let normalizedTurns = ((rotationQuarterTurns % 4) + 4) % 4
        return rotatedImageCache[normalizedTurns] ?? rotateImage(loadedImage, byQuarterTurns: normalizedTurns)
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
                    InsurancePDFDocumentContainerView(pdfData: loadedPdfData)
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
                        "No Insurance Document",
                        systemImage: "doc.text.image",
                        description: Text("Pull to refresh or try again.")
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
                            Text("Declined").tag(VerifyInsuranceAction.declined)
                            Text("Approved").tag(VerifyInsuranceAction.approved)
                        }
                        .pickerStyle(.segmented)

                        if selectedAction == .declined {
                            TextInputField(placeholder: "Reason", text: $actionReasonInput)
                        }

                        if selectedAction == .approved {
                            DatePicker(
                                "Liability Expiration",
                                selection: $insuranceLiabilityExpiration,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.compact)

                            Toggle("Collision Valid", isOn: $insuranceCollisionValid)
                        }

                        PrimaryButton(text: isSubmitting ? "Submitting..." : "Submit") {
                            submitVerification(selectedAction)
                        }
                    }
                    .disabled(isSubmitting || isLoading)
                    .padding()
                    .background(Color.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .background(Color.mainBG)
        .navigationTitle("Approve Insurance")
        .navigationBarTitleDisplayMode(.large)
        .scrollIndicators(.hidden)
        .onAppear {
            requestNextRenter()
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
                await loadNextRenterNeedInsuranceVerifyAsync(token, userId)
            }
        }
    }

    private func submitVerification(_ action: VerifyInsuranceAction) {
        guard !isSubmitting, !isLoading, let renter else { return }

        if action == .declined {
            let trimmedReason = actionReasonInput.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedReason.isEmpty {
                alertTitle = "Reason Required"
                alertMessage = "Please provide a reason to decline insurance."
                showAlert = true
                return
            }
        }

        isSubmitting = true
        Task {
            await ApiCallActor.shared.appendApi { token, userId in
                await verifyInsuranceAsync(
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
    private func loadNextRenterNeedInsuranceVerifyAsync(_ token: String, _ userId: Int) async -> ApiTaskResponse {
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
                    "renter-type": "ProofOfInsurance"
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

                    selectedAction = .declined
                    actionReasonInput = ""
                    if let expiration = decodedBody.renter.insuranceLiabilityExpiration,
                       let parsedDate = VeygoDatetimeStandard.shared.yyyyMMddDateFormatter.date(from: expiration) {
                        insuranceLiabilityExpiration = parsedDate
                    } else {
                        insuranceLiabilityExpiration = Date()
                    }
                    insuranceCollisionValid = decodedBody.renter.insuranceCollisionValid
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

    @ApiCallActor
    private func verifyInsuranceAsync(
        _ token: String,
        _ userId: Int,
        renterId: Int,
        action: VerifyInsuranceAction
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
                    reason: actionReasonInput.trimmingCharacters(in: .whitespacesAndNewlines),
                    expiration: insuranceLiabilityExpiration,
                    collisionValid: insuranceCollisionValid
                )
            }

            switch action {
            case .declined:
                struct DeclinedRequest: Encodable {
                    let type = "declined"
                    let renterId: Int
                    let reason: String
                }
                requestBodyData = try VeygoJsonStandard.shared.encoder.encode(
                    DeclinedRequest(
                        renterId: renterId,
                        reason: inputSnapshot.reason
                    )
                )
            case .approved:
                struct ApprovedRequest: Encodable {
                    let type = "approved"
                    let renterId: Int
                    let insuranceLiabilityExpiration: String
                    let insuranceCollisionValid: Bool
                }
                let expiration = VeygoDatetimeStandard.shared.yyyyMMddDateFormatter.string(from: inputSnapshot.expiration)
                requestBodyData = try VeygoJsonStandard.shared.encoder.encode(
                    ApprovedRequest(
                        renterId: renterId,
                        insuranceLiabilityExpiration: expiration,
                        insuranceCollisionValid: inputSnapshot.collisionValid
                    )
                )
            }

            let request = veygoCurlRequest(
                url: "/api/v1/admin/verify-insurance",
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

                    selectedAction = .declined
                    actionReasonInput = ""
                    if let expiration = decodedBody.renter.insuranceLiabilityExpiration,
                       let parsedDate = VeygoDatetimeStandard.shared.yyyyMMddDateFormatter.date(from: expiration) {
                        insuranceLiabilityExpiration = parsedDate
                    } else {
                        insuranceLiabilityExpiration = Date()
                    }
                    insuranceCollisionValid = decodedBody.renter.insuranceCollisionValid
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
                    1: rotateImage(image, byQuarterTurns: 1),
                    2: rotateImage(image, byQuarterTurns: 2),
                    3: rotateImage(image, byQuarterTurns: 3)
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
            // Keep placeholder when document cannot be loaded.
        }
    }

    private func rotateImage(_ image: UIImage, byQuarterTurns quarterTurns: Int) -> UIImage {
        let turns = ((quarterTurns % 4) + 4) % 4
        guard turns != 0 else { return image }

        var angle: CGFloat = 0
        switch turns {
        case 1:
            angle = .pi / 2
        case 2:
            angle = .pi
        default:
            angle = 3 * .pi / 2
        }

        let rotatedBounds = CGRect(origin: .zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: angle))
            .integral
        let newSize = CGSize(width: abs(rotatedBounds.width), height: abs(rotatedBounds.height))

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            let context = UIGraphicsGetCurrentContext()
            context?.translateBy(x: newSize.width / 2, y: newSize.height / 2)
            context?.rotate(by: angle)
            image.draw(in: CGRect(
                x: -image.size.width / 2,
                y: -image.size.height / 2,
                width: image.size.width,
                height: image.size.height
            ))
        }
    }
}

private struct InsurancePDFDocumentContainerView: UIViewRepresentable {
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
