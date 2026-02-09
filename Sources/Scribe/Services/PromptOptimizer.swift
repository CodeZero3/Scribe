import Foundation

@Observable
@MainActor
final class PromptOptimizer {
    var apiKey: String {
        get { UserDefaults.standard.string(forKey: "geminiAPIKey") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "geminiAPIKey") }
    }

    var selectedMode: OptimizationMode {
        get {
            let raw = UserDefaults.standard.string(forKey: "selectedOptimizationMode") ?? OptimizationMode.aiPrompts.rawValue
            return OptimizationMode(rawValue: raw) ?? .aiPrompts
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "selectedOptimizationMode") }
    }

    var optimizationUnlocked: Bool {
        get { UserDefaults.standard.bool(forKey: "optimizationUnlocked") }
        set { UserDefaults.standard.set(newValue, forKey: "optimizationUnlocked") }
    }

    var isOptimizing = false

    var isConfigured: Bool { !apiKey.isEmpty }

    func isModeAvailable(_ mode: OptimizationMode) -> Bool {
        !mode.requiresUnlock || optimizationUnlocked
    }

    func optimize(_ text: String, mode: OptimizationMode? = nil) async -> String {
        let activeMode = mode ?? selectedMode
        guard isConfigured else { return text }
        guard isModeAvailable(activeMode) else { return text }

        isOptimizing = true
        defer { isOptimizing = false }

        do {
            let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 15

            let body: [String: Any] = [
                "system_instruction": [
                    "parts": [
                        ["text": activeMode.systemPrompt]
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
                NSLog("[Scribe] PromptOptimizer: API returned status %d",
                      (response as? HTTPURLResponse)?.statusCode ?? -1)
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
