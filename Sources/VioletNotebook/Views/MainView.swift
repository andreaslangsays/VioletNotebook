import SwiftUI

struct MainView: View {
    @ObservedObject var journal: Journal
    @State private var selectedDate = Date()
    @State private var isEditMode = true
    @State private var editorText = ""
    @State private var showFolderPicker = false
    @State private var showExportSheet = false
    
    var body: some View {
        NavigationSplitView {
            SidebarView(journal: journal, selectedDate: $selectedDate, editorText: $editorText)
                .frame(minWidth: 260, maxWidth: 320)
        } detail: {
            VStack(spacing: 0) {
                // Detail Top Header
                HStack {
                    Button(action: { moveDay(by: -1) }) {
                        Image(systemName: "chevron.left")
                    }
                    Button(action: { selectedDate = Date() }) {
                        Text("Heute")
                    }
                    Button(action: { moveDay(by: 1) }) {
                        Image(systemName: "chevron.right")
                    }
                    
                    Spacer()
                    
                    Text(formattedDate(selectedDate))
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Picker("", selection: $isEditMode) {
                        Text("Edit").tag(true)
                        Text("Vorschau").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
                
                Divider()
                
                if isEditMode {
                    EditorView(text: $editorText)
                        .onChange(of: editorText) { newText in
                            saveCurrentDay(text: newText)
                        }
                } else {
                    PreviewWebView(htmlContent: Txt2TagsParser.toHTML(editorText), onDayLinkClick: { dateStr in
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        if let date = formatter.date(from: dateStr) {
                            selectedDate = date
                        }
                    })
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    Button(action: { showFolderPicker = true }) {
                        Label("Tagebuch öffnen", systemImage: "folder.badge.plus")
                    }
                    Button(action: { showExportSheet = true }) {
                        Label("Exportieren", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showFolderPicker) {
            VStack(spacing: 20) {
                Text("Tagebuch-Ordner auswählen")
                    .font(.headline)
                Text("Wähle das Verzeichnis aus, in dem deine RedNotebook-Einträge liegen.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Ordner wählen...") {
                    selectFolder()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .frame(width: 350, height: 200)
        }
        .sheet(isPresented: $showExportSheet) {
            ExportView(journal: journal, isPresented: $showExportSheet)
        }
        .onAppear {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            loadSavedFolder()
        }
        .onChange(of: selectedDate) { newDate in
            loadCurrentDay(date: newDate)
        }
    }
    
    private func moveDay(by offset: Int) {
        if offset < 0 {
            if let prevDate = journal.findPreviousEntryDate(from: selectedDate) {
                selectedDate = prevDate
                return
            }
        } else if offset > 0 {
            if let nextDate = journal.findNextEntryDate(from: selectedDate) {
                selectedDate = nextDate
                return
            }
        }
        
        if let newDate = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    private func loadCurrentDay(date: Date) {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        editorText = journal.entry(for: comps)?.text ?? ""
    }
    
    private func saveCurrentDay(text: String) {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        try? journal.saveEntry(text: text, date: comps)
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        
        if panel.runModal() == .OK, let url = panel.url {
            // Resolve bookmark
            if let bookmark = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
                UserDefaults.standard.set(bookmark, forKey: "journalFolderBookmark")
            }
            UserDefaults.standard.set(url.path, forKey: "journalFolderPath")
            
            // Load
            showFolderPicker = false
            journal.updateDirectory(to: url)
            try? journal.loadAll()
            loadCurrentDay(date: selectedDate)
        }
    }
    
    private func loadSavedFolder() {
        if let bookmarkData = UserDefaults.standard.data(forKey: "journalFolderBookmark") {
            var isStale = false
            if let url = try? URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                _ = url.startAccessingSecurityScopedResource()
                journal.updateDirectory(to: url)
                try? journal.loadAll()
                loadCurrentDay(date: selectedDate)
                return
            }
        }
        
        // No bookmark saved, prompt picker
        showFolderPicker = true
    }
}
