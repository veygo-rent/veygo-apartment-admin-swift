//
//  RenterView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 3/26/26.
//

import SwiftUI

private enum RenterDestination {
    case lookupRenter
    case approveLicense
    case approveLease
    case approveInsurance
    case lookupDoNotRent
}

private struct RenterActionTile: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let badgeText: String?
    let iconColor: Color
    let badgeColor: Color
    let destination: RenterDestination
    let requiresAdminStatus: Bool

    static func tiles(
        pendingDlApprovals: Int,
        pendingLeaseApprovals: Int,
        pendingInsuranceApprovals: Int
    ) -> [RenterActionTile] {
        [
            RenterActionTile(
                id: "lookup-renter",
                title: "Look Up Renter",
                subtitle: "Search by name, email, phone, or renter ID.",
                symbol: "magnifyingglass",
                badgeText: nil,
                iconColor: .blue,
                badgeColor: .secondary,
                destination: .lookupRenter,
                requiresAdminStatus: false
            ),
            RenterActionTile(
                id: "approve-license",
                title: "Approve Driver's License",
                subtitle: "Review pending submissions and validate expiration.",
                symbol: "creditcard.rewards",
                badgeText: pendingDlApprovals != 0 ? "\(pendingDlApprovals) Pending" : nil,
                iconColor: .green,
                badgeColor: .orange,
                destination: .approveLicense,
                requiresAdminStatus: true
            ),
            RenterActionTile(
                id: "approve-lease",
                title: "Approve Lease",
                subtitle: "Review lease documents and verify apartment assignment.",
                symbol: "doc.badge.clock",
                badgeText: pendingLeaseApprovals != 0 ? "\(pendingLeaseApprovals) Pending" : nil,
                iconColor: .indigo,
                badgeColor: .orange,
                destination: .approveLease,
                requiresAdminStatus: true
            ),
            RenterActionTile(
                id: "approve-insurance",
                title: "Approve Insurance",
                subtitle: "Validate insurance policy image and expiration.",
                symbol: "checkmark.shield",
                badgeText: pendingInsuranceApprovals != 0 ? "\(pendingInsuranceApprovals) Pending" : nil,
                iconColor: .teal,
                badgeColor: .orange,
                destination: .approveInsurance,
                requiresAdminStatus: true
            ),
            RenterActionTile(
                id: "lookup-dnr",
                title: "Lookup Do-Not-Rent",
                subtitle: "Search blocked renters by name, email, or phone.",
                symbol: "person.crop.circle.badge.exclamationmark",
                badgeText: nil,
                iconColor: .red,
                badgeColor: .secondary,
                destination: .lookupDoNotRent,
                requiresAdminStatus: false
            )
        ]
    }
}

struct RenterView: View {
    
    @EnvironmentObject private var session: AdminSession
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @State private var pendingDlApprovals = 0
    @State private var pendingLeaseApprovals = 0
    @State private var pendingInsuranceApprovals = 0
    @State private var isLoadingStats = false
    
    private let tileSpacing: CGFloat = 26
    private let minimumTileWidth: CGFloat = 180
    private let maximumTileWidth: CGFloat = 260

    var body: some View {
        if let admin = session.user {
            NavigationStack {
                ScrollView(.vertical) {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: minimumTileWidth, maximum: maximumTileWidth), spacing: tileSpacing)
                        ],
                        spacing: tileSpacing
                    ) {
                        ForEach(
                            RenterActionTile.tiles(
                                pendingDlApprovals: pendingDlApprovals,
                                pendingLeaseApprovals: pendingLeaseApprovals,
                                pendingInsuranceApprovals: pendingInsuranceApprovals
                            )
                        ) { tile in
                            if tile.requiresAdminStatus && admin.employeeTier == EmployeeTier.admin || !tile.requiresAdminStatus {
                                NavigationLink {
                                    destinationView(for: tile.destination)
                                } label: {
                                    TileView(
                                        title: tile.title,
                                        subtitle: tile.subtitle,
                                        symbol: tile.symbol,
                                        badgeText: tile.badgeText,
                                        iconColor: tile.iconColor,
                                        badgeColor: tile.badgeColor
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.mainBG)
                .navigationTitle("Renters")
                .onAppear {
                    requestRenterStats()
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") {
                    if clearUserTriggered {
                        session.user = nil
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }

    @ViewBuilder
    private func destinationView(for destination: RenterDestination) -> some View {
        switch destination {
        case .lookupRenter:
            RenterFeaturePlaceholderView(title: "Look Up Renter")
        case .approveLicense:
            RenterFeaturePlaceholderView(title: "Approve Driver's License")
        case .approveLease:
            RenterFeaturePlaceholderView(title: "Approve Lease")
        case .approveInsurance:
            RenterFeaturePlaceholderView(title: "Approve Insurance")
        case .lookupDoNotRent:
            RenterFeaturePlaceholderView(title: "Lookup Do-Not-Rent")
        }
    }

    private func requestRenterStats() {
        guard !isLoadingStats else { return }
        isLoadingStats = true
        Task {
            await ApiCallActor.shared.appendApi { token, userId in
                await renterStatsRequestAsync(token, userId)
            }
        }
    }

    @ApiCallActor
    private func renterStatsRequestAsync(_ token: String, _ userId: Int) async -> ApiTaskResponse {
        defer {
            Task { @MainActor in
                isLoadingStats = false
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
                url: "/api/v1/admin/stats/renters",
                method: .get,
                headers: ["auth": "\(token)$\(userId)"]
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
                guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(RentersStats.self, from: data) else {
                    return .doNothing
                }
                await MainActor.run {
                    pendingDlApprovals = decodedBody.pendingDlApprovals
                    pendingLeaseApprovals = decodedBody.pendingLeaseApprovals
                    pendingInsuranceApprovals = decodedBody.pendingInsuranceApprovals
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
            case 405:
                if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                    }
                } else {
                    let decodedBody = ErrorResponse.E405
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
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
}

private struct RenterFeaturePlaceholderView: View {
    let title: String

    var body: some View {
        List {
            Section {
                Label(title, systemImage: "hammer")
            }
            Section("Next Step") {
                Text("Replace this placeholder with the real \(title.lowercased()) screen.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(title)
    }
}
