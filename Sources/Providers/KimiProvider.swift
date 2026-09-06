import Foundation
import os

/// Reads Kimi usage from the Moonshot API, using an API key borrowed from
/// local Kimi configuration or environment.
///
/// The Moonshot API does not publish a documented usage endpoint, so this
/// provider probes the most likely paths and degrades gracefully when none
/// respond with readable data.
actor KimiProvider: UsageProvider {
    nonisolated let id = "kimi"
    nonisolated let displayName = "Kimi"
    nonisolated let glyph = ProviderGlyph.kimi

    private let session: URLSession
    private let archive: UsageArchive
    private var retryNoEarlierThan: Date?
    private var consecutiveRateLimits = 0

    init(session: URLSession = .shared, archive: UsageArchive = UsageArchive()) {
        self.session = session
        self.archive = archive
        self.retryNoEarlierThan = archive.loadBackoffUntil(providerID: id)
    }

    nonisolated var signInRoute: SignInRoute {
        .guidance("Set a KIMI_API_KEY environment variable, or place your key "
                  + "in ~/.kimi/config.json { \"api_key\": \"...\" } to read Kimi usage.")
    }

    nonisolated func forgetCachedCredential() {
        // Nothing cached; re-read from disk on every fetch.
    }

    nonisolated func account() -> ProviderAccount? {
        guard let credentials = KimiCredentials.load() else { return nil }
        return ProviderAccount(
            label: credentials.label,
            plan: nil,
            source: "Kimi config",
            manageURL: URL(string: "https://platform.moonshot.cn/")
        )
    }

    func fetchSnapshot() async throws -> ProviderSnapshot {
        if let retryNoEarlierThan, retryNoEarlierThan > Date() {
            let remaining = retryNoEarlierThan.timeIntervalSinceNow
            Log.usage.debug("kimi: skipping fetch, backing off for \(remaining, format: .fixed(precision: 0))s")
            throw UsageProviderError.rateLimited(retryAfter: remaining)
        }

        guard let credentials = KimiCredentials.load() else {
            throw UsageProviderError.needsAuth
        }

        do {
            let data = try await fetch(credentials: credentials)
            let windows = try parseUsage(data)

            consecutiveRateLimits = 0
            retryNoEarlierThan = nil
            archive.saveBackoffUntil(nil, providerID: id)

            return ProviderSnapshot(
                id: id,
                displayName: displayName,
                glyph: glyph,
                fidelity: .derived,
                status: .ok,
                windows: windows,
                headlineID: "kimi.daily"
            )
        } catch UsageProviderError.rateLimited(let retryAfter) {
            consecutiveRateLimits += 1
            retryNoEarlierThan = Date().addingTimeInterval(retryAfter)
            archive.saveBackoffUntil(retryNoEarlierThan, providerID: id)
            Log.usage.notice("kimi: rate limited (\(self.consecutiveRateLimits)x), next attempt in \(retryAfter, format: .fixed(precision: 0))s")
            throw UsageProviderError.rateLimited(retryAfter: retryAfter)
        }
    }

    private func fetch(credentials: KimiCredentials.Credential) async throws -> Data {
        let url = URL(string: "https://api.moonshot.cn/v1/users/me/usage")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(credentials.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        Log.usage.debug("GET api.moonshot.cn/v1/users/me/usage")
        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        Log.usage.debug("kimi usage endpoint answered \(status)")

        if status == 401 || status == 403 { throw UsageProviderError.needsAuth }
        if status == 404 {
            throw UsageProviderError.nothingMetered("Kimi API does not expose a usage endpoint.")
        }
        if status == 429 {
            throw UsageProviderError.rateLimited(
                retryAfter: Self.backoff(
                    forAttempt: consecutiveRateLimits,
                    retryAfter: Self.retryAfter(from: response)
                )
            )
        }
        guard (200..<300).contains(status) else {
            throw UsageProviderError.badResponse(status: status)
        }
        return data
    }

    private func parseUsage(_ data: Data) throws -> [LimitWindow] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw UsageProviderError.badResponse(status: 200)
        }

        var windows: [LimitWindow] = []

        if let used = json["used"] as? Double, let limit = json["limit"] as? Double, limit > 0 {
            windows.append(LimitWindow(
                id: "kimi.daily",
                label: "Daily usage",
                usedFraction: used / limit,
                remaining: Int(max(0, limit - used)),
                used: Int(used)
            ))
        } else if let remaining = json["remaining"] as? Int, let total = json["total"] as? Int, total > 0 {
            windows.append(LimitWindow(
                id: "kimi.daily",
                label: "Daily usage",
                usedFraction: Double(total - remaining) / Double(total),
                remaining: remaining,
                used: total - remaining
            ))
        } else if let balance = json["balance"] as? Double {
            windows.append(LimitWindow(
                id: "kimi.balance",
                label: "API balance",
                remaining: Int(balance)
            ))
        }

        if windows.isEmpty {
            throw UsageProviderError.nothingMetered("Kimi API returned unreadable usage data.")
        }

        return windows
    }

    static func backoff(forAttempt attempt: Int, retryAfter: TimeInterval?) -> TimeInterval {
        let floor: TimeInterval = 60
        let ceiling: TimeInterval = 15 * 60
        let doubled = floor * pow(2, Double(min(attempt, 4)))
        return min(ceiling, max(doubled, retryAfter ?? 0))
    }

    static func retryAfter(from response: URLResponse?) -> TimeInterval? {
        guard let header = (response as? HTTPURLResponse)?
            .value(forHTTPHeaderField: "Retry-After")?
            .trimmingCharacters(in: .whitespaces)
        else { return nil }

        if let seconds = TimeInterval(header) { return max(0, seconds) }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        guard let date = formatter.date(from: header) else { return nil }
        return max(0, date.timeIntervalSinceNow)
    }
}
