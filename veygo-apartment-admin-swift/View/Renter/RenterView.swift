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

    static let tiles: [RenterActionTile] = [
        RenterActionTile(
            id: "lookup-renter",
            title: "Look Up Renter",
            subtitle: "Search by name, email, phone, or renter ID.",
            symbol: "magnifyingglass",
            badgeText: nil,
            iconColor: .blue,
            badgeColor: .secondary,
            destination: .lookupRenter
        ),
        RenterActionTile(
            id: "approve-license",
            title: "Approve Driver's License",
            subtitle: "Review pending submissions and validate expiration.",
            symbol: "creditcard.rewards",
            badgeText: "12 Pending",
            iconColor: .green,
            badgeColor: .orange,
            destination: .approveLicense
        ),
        RenterActionTile(
            id: "approve-lease",
            title: "Approve Lease",
            subtitle: "Review lease documents and verify apartment assignment.",
            symbol: "doc.badge.clock",
            badgeText: nil,
            iconColor: .indigo,
            badgeColor: .orange,
            destination: .approveLease
        ),
        RenterActionTile(
            id: "approve-insurance",
            title: "Approve Insurance",
            subtitle: "Validate insurance policy image and expiration.",
            symbol: "checkmark.shield",
            badgeText: nil,
            iconColor: .teal,
            badgeColor: .secondary,
            destination: .approveInsurance
        ),
        RenterActionTile(
            id: "lookup-dnr",
            title: "Lookup Do-Not-Rent",
            subtitle: "Search blocked renters by name, email, or phone.",
            symbol: "person.crop.circle.badge.exclamationmark",
            badgeText: nil,
            iconColor: .red,
            badgeColor: .secondary,
            destination: .lookupDoNotRent
        )
    ]
}

struct RenterView: View {
    private let tileSpacing: CGFloat = 26
    private let minimumTileWidth: CGFloat = 180
    private let maximumTileWidth: CGFloat = 260

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: minimumTileWidth, maximum: maximumTileWidth), spacing: tileSpacing)
                    ],
                    spacing: tileSpacing
                ) {
                    ForEach(RenterActionTile.tiles) { tile in
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
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.mainBG)
            .navigationTitle("Renters")
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
