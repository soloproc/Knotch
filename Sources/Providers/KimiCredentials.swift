import Foundation

/// Reads a Kimi (Moonshot) API key from local configuration or environment.
enum KimiCredentials {
    struct Credential {
        let token: String
        let label: String?
    }

    static func load() -> Credential? {
        // 1. Environment variable
        if let token = ProcessInfo.processInfo.environment["KIMI_API_KEY"], !token.isEmpty {
            return Credential(token: token, label: nil)
        }

        // 2. ~/.kimi/config.json
        let home = FileManager.default.homeDirectoryForCurrentUser
        let configURL = home.appendingPathComponent(".kimi/config.json")
        if let data = try? Data(contentsOf: configURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let token = json["api_key"] as? String ?? json["token"] as? String,
           !token.isEmpty {
            let label = json["label"] as? String
            return Credential(token: token, label: label)
        }

        // 3. ~/.kimi/api_key (plain text file)
        let keyFileURL = home.appendingPathComponent(".kimi/api_key")
        if let token = try? String(contentsOf: keyFileURL, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
           !token.isEmpty {
            return Credential(token: token, label: nil)
        }

        return nil
    }
}
