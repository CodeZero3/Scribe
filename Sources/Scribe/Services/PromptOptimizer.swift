import Foundation

@Observable
@MainActor
final class PromptOptimizer {
    var apiKey: String {
        get { UserDefaults.standard.string(forKey: "geminiAPIKey") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "geminiAPIKey") }
    }

    var isOptimizing = false

    var isConfigured: Bool { !apiKey.isEmpty }

    func optimize(_ text: String) async -> String {
        guard isConfigured else { return text }
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
                        ["text": """
                        You are a prompt optimization assistant. The user has dictated text using voice-to-text. \
                        Your job is to restructure it into a clear, well-formatted prompt optimized for AI consumption.

                        Rules:
                        - Preserve the user's original intent completely
                        - Fix grammar, remove filler words, improve clarity
                        - Structure with clear sections if the request is complex
                        - Use imperative/direct language appropriate for AI prompts
                        - Do NOT add information the user didn't express
                        - Do NOT wrap in quotes or add meta-commentary
                        - Return ONLY the optimized prompt text, nothing else
                        """]
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
