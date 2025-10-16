import SwiftUI

struct VocabularyManagementView: View {
    @Binding var vocabulary: CustomVocabulary
    @State private var newSource = ""
    @State private var newReplacement = ""
    @State private var newCategory: VocabularyCategory = .custom
    @State private var newCaseSensitive = false
    @State private var editingEntry: VocabularyEntry?
    @State private var showingImportExport = false
    @State private var searchText = ""
    @State private var selectedCategory: VocabularyCategory?

    var body: some View {
        VStack(spacing: 0) {
            addEntrySection
            Divider()
            entriesListSection
        }
    }

    private var addEntrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(editingEntry == nil ? "Add New Entry" : "Edit Entry")
                .font(.headline)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Source Text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g., 'AI' or 'Jay-vee-err'", text: $newSource)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Replacement")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g., 'Artificial Intelligence' or 'Javier'", text: $newReplacement)
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack(spacing: 12) {
                Picker("Category", selection: $newCategory) {
                    ForEach(VocabularyCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .frame(maxWidth: 200)

                Toggle("Case Sensitive", isOn: $newCaseSensitive)

                Spacer()

                if editingEntry != nil {
                    Button("Cancel") {
                        cancelEditing()
                    }
                }

                Button(editingEntry == nil ? "Add" : "Update") {
                    if editingEntry != nil {
                        updateEntry()
                    } else {
                        addEntry()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newSource.isEmpty || newReplacement.isEmpty)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var entriesListSection: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Search entries...", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                Picker("Filter", selection: $selectedCategory) {
                    Text("All Categories").tag(nil as VocabularyCategory?)
                    ForEach(VocabularyCategory.allCases) { category in
                        Text(category.rawValue).tag(category as VocabularyCategory?)
                    }
                }
                .frame(maxWidth: 200)

                Button {
                    showingImportExport = true
                } label: {
                    Label("Import/Export", systemImage: "square.and.arrow.up")
                }
            }
            .padding()

            if filteredEntries.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredEntries) { entry in
                            VocabularyEntryRow(
                                entry: entry,
                                onEdit: {
                                    startEditing(entry)
                                },
                                onDelete: {
                                    deleteEntry(entry)
                                }
                            )
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingImportExport) {
            ImportExportView(vocabulary: $vocabulary)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "No vocabulary entries" : "No matching entries")
                .font(.callout)
                .foregroundStyle(.secondary)
            if searchText.isEmpty {
                Text("Add custom words and phrases to improve transcription accuracy")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }

    private var filteredEntries: [VocabularyEntry] {
        var entries = vocabulary.entries

        if let category = selectedCategory {
            entries = entries.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            entries = entries.filter {
                $0.source.localizedCaseInsensitiveContains(searchText) ||
                $0.replacement.localizedCaseInsensitiveContains(searchText)
            }
        }

        return entries.sorted { $0.source.localizedCompare($1.source) == .orderedAscending }
    }

    private func addEntry() {
        let entry = VocabularyEntry(
            source: newSource.trimmingCharacters(in: .whitespaces),
            replacement: newReplacement.trimmingCharacters(in: .whitespaces),
            caseSensitive: newCaseSensitive,
            category: newCategory
        )
        vocabulary.add(entry)
        clearForm()
    }

    private func updateEntry() {
        guard let editing = editingEntry else { return }

        let updated = VocabularyEntry(
            id: editing.id,
            source: newSource.trimmingCharacters(in: .whitespaces),
            replacement: newReplacement.trimmingCharacters(in: .whitespaces),
            caseSensitive: newCaseSensitive,
            category: newCategory
        )
        vocabulary.update(updated)
        clearForm()
    }

    private func deleteEntry(_ entry: VocabularyEntry) {
        vocabulary.remove(entry)
    }

    private func startEditing(_ entry: VocabularyEntry) {
        editingEntry = entry
        newSource = entry.source
        newReplacement = entry.replacement
        newCategory = entry.category
        newCaseSensitive = entry.caseSensitive
    }

    private func cancelEditing() {
        clearForm()
    }

    private func clearForm() {
        newSource = ""
        newReplacement = ""
        newCategory = .custom
        newCaseSensitive = false
        editingEntry = nil
    }
}

struct VocabularyEntryRow: View {
    let entry: VocabularyEntry
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(entry.source)
                        .font(.body)
                        .fontWeight(.medium)

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(entry.replacement)
                        .font(.body)
                }

                HStack(spacing: 8) {
                    Text(entry.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(4)

                    if entry.caseSensitive {
                        Text("Case Sensitive")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

struct ImportExportView: View {
    @Binding var vocabulary: CustomVocabulary
    @Environment(\.dismiss) private var dismiss
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var exportData: Data?
    @State private var importError: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Import/Export Vocabulary")
                .font(.headline)

            VStack(spacing: 12) {
                Button {
                    exportVocabulary()
                } label: {
                    Label("Export to JSON", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    showingImporter = true
                } label: {
                    Label("Import from JSON", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }

                if let error = importError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()

            Spacer()

            Button("Close") {
                dismiss()
            }
        }
        .padding()
        .frame(width: 400, height: 300)
        .fileExporter(
            isPresented: $showingExporter,
            document: JSONDocument(data: exportData ?? Data()),
            contentType: .json,
            defaultFilename: "vocabulary.json"
        ) { result in
            if case .failure(let error) = result {
                importError = "Export failed: \(error.localizedDescription)"
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json]
        ) { result in
            handleImport(result)
        }
    }

    private func exportVocabulary() {
        let repository = VocabularyRepository()
        exportData = repository.exportToJSON()
        showingExporter = true
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                importError = "Cannot access file"
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                let repository = VocabularyRepository()
                if repository.importFromJSON(data) {
                    vocabulary = repository.load()
                    importError = nil
                    dismiss()
                } else {
                    importError = "Invalid vocabulary file format"
                }
            } catch {
                importError = "Import failed: \(error.localizedDescription)"
            }

        case .failure(let error):
            importError = "Import failed: \(error.localizedDescription)"
        }
    }
}

struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

import UniformTypeIdentifiers
