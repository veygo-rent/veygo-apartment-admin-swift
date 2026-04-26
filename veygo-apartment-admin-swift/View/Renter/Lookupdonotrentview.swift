//
//  Lookupdonotrentview.swift
//  veygo-apartment-admin-swift
//
//  Created by Sathvik Seema on 4/26/26.
//

import SwiftUI

struct LookUpDoNotRentView: View {
    @EnvironmentObject private var session: AdminSession

    @State private var searchInput: String = ""
    @State private var results: [DoNotRentList] = []
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
                    TextInputField(placeholder: "Name, email, or phone", text: $searchInput)
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
                        "No Results Found",
                        systemImage: "person.slash",
                        description: Text("Try a different name, email, or phone.")
                    )
                } else {
                    ForEach(results) { entry in
                        DoNotRentResultRow(entry: entry)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .scrollContentBackground(.hidden)
        .background(Color.mainBG)
        .navigationTitle("Lookup Do-Not-Rent")
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
                await searchDoNotRentAsync(token, userId, query: query)
            }
        }
    }

    @ApiCallActor
    private func searchDoNotRentAsync(_ token: String, _ userId: Int, query: String) async -> ApiTaskResponse {
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

            guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return .doNothing
            }

            let request = veygoCurlRequest(
                url: "/api/v1/admin/do-not-rent?q=\(encodedQuery)",
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
                guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode([DoNotRentList].self, from: data) else {
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

private struct DoNotRentResultRow: View {
    let entry: DoNotRentList

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.name ?? "Unknown")
                    .font(.headline)
                Spacer()
                Text("#\(entry.id)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let email = entry.email {
                Text(email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let phone = entry.phone {
                Text(phone)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(entry.note)
                .font(.subheadline)
                .foregroundStyle(.red)
            if let exp = entry.exp {
                Text("Expires: \(exp)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
