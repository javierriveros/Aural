import SwiftUI

struct FillerWordsManagementView: View {
    @Binding var configuration: FillerWordsConfiguration
    @Environment(\.dismiss) private var dismiss
    @State private var newWord = ""

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            inputSection
            Divider()
            listSection
        }
        .frame(width: 400, height: 500)
    }

    private var headerSection: some View {
        HStack {
            Text("Manage Filler Words")
                .font(.headline)
            Spacer()
            Button("Reset to Defaults") {
                configuration.resetToDefaults()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
    }

    private var inputSection: some View {
        HStack(spacing: 12) {
            TextField("Add filler word (e.g., 'like')", text: $newWord)
                .textFieldStyle(.roundedBorder)
                .onSubmit { addWord() }

            Button("Add") {
                addWord()
            }
            .buttonStyle(.bordered)
            .disabled(newWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var listSection: some View {
        VStack(spacing: 0) {
            if configuration.words.isEmpty {
                ContentUnavailableView {
                    Label("No Filler Words", systemImage: "text.bubble")
                } description: {
                    Text("Add words to be removed from transcriptions")
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(configuration.words.sorted(), id: \.self) { word in
                        HStack {
                            Text(word)
                                .font(.body)
                            Spacer()
                            Button {
                                deleteWord(word)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .onHover { isHovering in
                                if isHovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    private func addWord() {
        let trimmed = newWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if !configuration.words.contains(where: { $0.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) {
            configuration.words.append(trimmed)
            configuration.words.sort()
        }
        newWord = ""
    }

    private func deleteWord(_ word: String) {
        withAnimation {
            configuration.words.removeAll { $0 == word }
        }
    }
}

#Preview {
    FillerWordsManagementView(configuration: .constant(FillerWordsConfiguration(isEnabled: true)))
}
