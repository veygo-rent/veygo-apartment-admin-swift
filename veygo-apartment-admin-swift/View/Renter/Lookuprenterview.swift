//
//  Lookuprenterview.swift
//  veygo-apartment-admin-swift
//
//  Created by Sathvik Seema on 4/26/26.
//

import SwiftUI

struct LookUpRenterView: View {
    @EnvironmentObject private var session: AdminSession

    @State private var searchInput: String = ""
    @State private var results: [PublishRenter] = []
    @State private var isLoading = false
    @State private var hasSearched = false

    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var clearUserTriggered: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Search bar
                VStack(alignment: .leading, spacing: 10) {
                    TextInputField(placeholder: "Name, email, phone, or renter ID", text: $searchInput)
                    PrimaryButton(text: isLoading ? "Searching..." : "Search") {
                        performSearch()
                    }
                    .disabled(isLoading || searchInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(Color.cardBG)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Results
                if isLoading {
                    LoadingView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(Color.cardBG)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if hasSearched && results.isEmpty {
                    ContentUnavailableView(
                        "No Renters Found",
                        systemImage: "person.slash",
                        description: Text("Try a different name, email, phone, or renter ID.")
                    )
                } else {
                    ForEach(results) { renter in
                        RenterResultRow(renter: renter)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .scrollContentBackground(.hidden)
        .background(Color.mainBG)
        .navigationTitle("Look Up Renter")
        .navigationBarTitleDisplayMode(.large)
        .scrollIndicators(.hidden)
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

    private func performSearch() {
        let query = searchInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, !isLoading else { return }
        isLoading = true
        hasSearched = false
        Task {
            await ApiCallActor.shared.appendApi { token, userId in
                await searchRentersAsync(token, userId, query: query)
            }
        }
    }

    @ApiCallActor
    private func searchRentersAsync(_ token: String, _ userId: Int, query: String) async -> ApiTaskResponse {
        defer {
            Task { @MainActor in
                isLoading = false
                hasSearched = true
            }
        }

        do {
            guard !token.isEmpty, userId > 0 else {
                await MainActor.run {
                    let body = ErrorResponse.E401
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                    clearUserTriggered = true
                }
                return .clearUser
            }

            // Encode query param safely
            guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return .doNothing
            }

            let request = veygoCurlRequest(
                url: "/api/v1/admin/renter?q=\(encodedQuery)",
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
                guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode([PublishRenter].self, from: data) else {
                    await MainActor.run {
                        let body = ErrorResponse.E_DEFAULT
                        alertTitle = body.title
                        alertMessage = body.message
                        showAlert = true
                    }
                    return .doNothing
                }
                await MainActor.run {
                    results = decodedBody
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
                    let body = ErrorResponse.E401
                    await MainActor.run {
                        alertTitle = body.title
                        alertMessage = body.message
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
                    let body = ErrorResponse.E405
                    await MainActor.run {
                        alertTitle = body.title
                        alertMessage = body.message
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

// MARK: - Result Row

private struct RenterResultRow: View {
    let renter: PublishRenter

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(renter.name)
                    .font(.headline)
                Spacer()
                Text("#\(renter.id)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(renter.studentEmail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(renter.phone)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Text(renter.planTier.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
                Text(renter.employeeTier.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.purple.opacity(0.15))
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
