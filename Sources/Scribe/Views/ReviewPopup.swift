import SwiftUI

struct ReviewPopup: View {
    @Environment(DictationManager.self) private var manager
    @Environment(\.dismissWindow) private var dismissWindow

    @State private var editableText: String = ""
    @State private var showChanges: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text("Review Transcription")
                .font(.headline)

            // Editable text area
            TextEditor(text: $editableText)
                .font(.body)
                .frame(minHeight: 120, maxHeight: 300)
                .border(Color.secondary.opacity(0.3), width: 1)
                .scrollContentBackground(.visible)

            // Changes section
            if let result = manager.pendingCleanupResult, !result.changes.isEmpty {
                DisclosureGroup("Changes (\(result.changes.count))", isExpanded: $showChanges) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(result.changes, id: \.self) { change in
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                Text(change)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .font(.subheadline)
            }

            Divider()

            // Action buttons
            HStack {
                Button("Cancel") {
                    manager.cancelReview()
                    dismissWindow(id: "review")
                }
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Button("Insert Original") {
                    manager.insertOriginal()
                    dismissWindow(id: "review")
                }

                Button("Insert") {
                    manager.insertReviewed(text: editableText)
                    dismissWindow(id: "review")
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(minWidth: 420, idealWidth: 500, minHeight: 280, idealHeight: 350)
        .onAppear {
            if let result = manager.pendingCleanupResult {
                editableText = result.cleaned
            }
        }
    }
}
