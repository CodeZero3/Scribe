import Foundation

@Observable
@MainActor
final class PromptOptimizer {
    var apiKey: String {
        get { UserDefaults.standard.string(forKey: "geminiAPIKey") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "geminiAPIKey") }
    }

    var enabledModes: Set<OptimizationMode> {
        get {
            guard let raw = UserDefaults.standard.stringArray(forKey: "enabledOptimizationModes") else {
                return [.aiPrompts]
            }
            let modes = raw.compactMap { OptimizationMode(rawValue: $0) }
            return Set(modes)
        }
        set {
            UserDefaults.standard.set(newValue.map(\.rawValue), forKey: "enabledOptimizationModes")
        }
    }

    func isModeEnabled(_ mode: OptimizationMode) -> Bool {
        enabledModes.contains(mode)
    }

    func toggleMode(_ mode: OptimizationMode) {
        var modes = enabledModes
        if modes.contains(mode) {
            modes.remove(mode)
        } else {
            modes.insert(mode)
        }
        enabledModes = modes
    }

    var optimizationUnlocked: Bool {
        get {
            // Default to unlocked; flip to false when StoreKit gating is added
            UserDefaults.standard.object(forKey: "optimizationUnlocked") == nil
                ? true
                : UserDefaults.standard.bool(forKey: "optimizationUnlocked")
        }
        set { UserDefaults.standard.set(newValue, forKey: "optimizationUnlocked") }
    }

    var isOptimizing = false

    var isConfigured: Bool { !apiKey.isEmpty }

    func isModeAvailable(_ mode: OptimizationMode) -> Bool {
        !mode.requiresUnlock || optimizationUnlocked
    }

    func optimizeWithEnabledModes(_ text: String) async -> String {
        guard isConfigured else { return text }
        let orderedModes = OptimizationMode.allCases.filter { enabledModes.contains($0) && isModeAvailable($0) }
        guard !orderedModes.isEmpty else { return text }

        var result = text
        for mode in orderedModes {
            result = await optimize(result, mode: mode)
        }
        return result
    }

    func optimize(_ text: String, mode: OptimizationMode) async -> String {
        guard isConfigured else { return text }
        guard isModeAvailable(mode) else { return text }

        isOptimizing = true
        defer { isOptimizing = false }

        do {
            let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=\(apiKey)")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 15

            let body: [String: Any] = [
                "system_instruction": [
                    "parts": [
                        ["text": mode.systemPrompt]
                    ]
                ],
                "contents": [
                    [
                        "parts": [
                            ["text": text]
                        ]
                    ]
                ],
                "generationConfig": [
                    "temperature": 0.3,
                    "maxOutputTokens": 2048
                ]
            ]

            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                let body = String(data: data, encoding: .utf8) ?? "no body"
                NSLog("[Scribe] PromptOptimizer: API returned status %d — %@", status, body)
                return text
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let optimized = parts.first?["text"] as? String,
                  !optimized.isEmpty else {
                NSLog("[Scribe] PromptOptimizer: Failed to parse response")
                return text
            }

            return optimized.trimmingCharacters(in: .whitespacesAndNewlines)

        } catch {
            NSLog("[Scribe] PromptOptimizer error: %@", error.localizedDescription)
            return text
        }
    }
}
