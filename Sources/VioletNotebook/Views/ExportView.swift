import SwiftUI
import WebKit
import UniformTypeIdentifiers

// MARK: - Export Compiler
@MainActor
struct ExportCompiler {
    static func getFilteredSortedEntries(from start: Date, to end: Date, in journal: Journal) -> [(date: Date, text: String)] {
        let cal = Calendar(identifier: .gregorian)
        let rangeStart = cal.startOfDay(for: start)
        let rangeEnd = cal.startOfDay(for: end)
        
        var results: [(date: Date, text: String)] = []
        for month in journal.months.values {
            for (day, dayData) in month.days {
                let comps = DateComponents(year: month.year, month: month.month, day: day)
                guard let date = cal.date(from: comps) else { continue }
                let normalizedDate = cal.startOfDay(for: date)
                
                if normalizedDate >= rangeStart && normalizedDate <= rangeEnd {
                    if !dayData.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        results.append((date: date, text: dayData.text))
                    }
                }
            }
        }
        return results.sorted(by: { $0.date < $1.date })
    }
    
    static func compileText(from start: Date, to end: Date, in journal: Journal) -> String {
        let entries = getFilteredSortedEntries(from: start, to: end, in: journal)
        let headerFormatter = DateFormatter()
        headerFormatter.locale = Locale(identifier: "de_DE")
        headerFormatter.dateFormat = "EEEE, dd.MM.yyyy"
        
        let formatted = entries.map { entry in
            let dateStr = headerFormatter.string(from: entry.date)
            return "=== \(dateStr) ===\n\n\(entry.text)\n"
        }
        return formatted.joined(separator: "\n")
    }
    
    static func compileHTML(from start: Date, to end: Date, in journal: Journal) -> String {
        let entries = getFilteredSortedEntries(from: start, to: end, in: journal)
        let headerFormatter = DateFormatter()
        headerFormatter.locale = Locale(identifier: "de_DE")
        headerFormatter.dateFormat = "EEEE, dd.MM.yyyy"
        
        var bodyHTML = ""
        for entry in entries {
            let dateStr = headerFormatter.string(from: entry.date)
            let entryHTML = Txt2TagsParser.toHTML(entry.text)
            bodyHTML += """
            <div class="entry">
                <div class="entry-date">\(dateStr)</div>
                <div class="entry-content">
                    \(entryHTML)
                </div>
            </div>
            """
        }
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    font-size: 14px;
                    line-height: 1.6;
                    padding: 32px;
                    background-color: #ffffff;
                    color: #1c1c1e;
                }
                h1, h2, h3 { color: #5a2d82; }
                a { color: #7f34c2; text-decoration: none; }
                a:hover { text-decoration: underline; }
                .hashtag {
                    color: #a855f7;
                    font-weight: 500;
                }
                .entry {
                    margin-bottom: 32px;
                    page-break-inside: avoid;
                }
                .entry-date {
                    border-bottom: 2px solid #e2e8f0;
                    padding-bottom: 4px;
                    margin-bottom: 12px;
                    font-size: 18px;
                    font-weight: bold;
                    color: #5a2d82;
                }
            </style>
        </head>
        <body>
            \(bodyHTML)
        </body>
        </html>
        """
    }
}

// MARK: - PDF Exporter Helper
@MainActor
class PDFExporter: NSObject, WKNavigationDelegate {
    private var webView: WKWebView?
    private var completion: ((Result<Data, Error>) -> Void)?
    
    func exportHTMLToPDF(html: String, completion: @escaping (Result<Data, Error>) -> Void) {
        self.completion = completion
        
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
        webView.navigationDelegate = self
        self.webView = webView
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let config = WKPDFConfiguration()
        webView.createPDF(configuration: config) { [weak self] result in
            guard let self = self else { return }
            self.completion?(result)
            self.completion = nil
            self.webView = nil
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        completion?(.failure(error))
        completion = nil
        self.webView = nil
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        completion?(.failure(error))
        completion = nil
        self.webView = nil
    }
}

@MainActor
class ExporterWrapper: ObservableObject {
    let exporter = PDFExporter()
}

// MARK: - Export Format Enum
enum ExportFormat: String, CaseIterable, Identifiable {
    case txt = "Text (.txt)"
    case html = "HTML (.html)"
    case pdf = "PDF (.pdf)"
    
    var id: String { self.rawValue }
    
    var utType: UTType {
        switch self {
        case .txt: return .plainText
        case .html: return .html
        case .pdf: return .pdf
        }
    }
    
    var fileExtension: String {
        switch self {
        case .txt: return "txt"
        case .html: return "html"
        case .pdf: return "pdf"
        }
    }
}

// MARK: - ExportView SwiftUI
struct ExportView: View {
    @ObservedObject var journal: Journal
    @Binding var isPresented: Bool
    
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var exportFormat: ExportFormat = .txt
    @State private var isExporting = false
    @State private var errorMessage: String? = nil
    
    @StateObject private var exporterWrapper = ExporterWrapper()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tagebuch exportieren")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                DatePicker("Startdatum:", selection: $startDate, displayedComponents: .date)
                    .datePickerStyle(.field)
                
                DatePicker("Enddatum:", selection: $endDate, displayedComponents: .date)
                    .datePickerStyle(.field)
            }
            .padding(.horizontal)
            
            Picker("Format:", selection: $exportFormat) {
                ForEach(ExportFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            if startDate > endDate {
                Text("Das Startdatum darf nicht nach dem Enddatum liegen.")
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                if isExporting {
                    ProgressView()
                        .controlSize(.small)
                }
                
                Spacer()
                
                Button("Abbrechen") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                .disabled(isExporting)
                
                Button("Exportieren...") {
                    runExport()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isExporting || startDate > endDate)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 400, height: 250)
    }
    
    private func runExport() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [exportFormat.utType]
        panel.nameFieldStringValue = "export.\(exportFormat.fileExtension)"
        
        if panel.runModal() == .OK, let url = panel.url {
            isExporting = true
            errorMessage = nil
            
            switch exportFormat {
            case .txt:
                let text = ExportCompiler.compileText(from: startDate, to: endDate, in: journal)
                do {
                    try text.write(to: url, atomically: true, encoding: .utf8)
                    isPresented = false
                } catch {
                    errorMessage = "Fehler beim Schreiben der Datei: \(error.localizedDescription)"
                }
                isExporting = false
            case .html:
                let html = ExportCompiler.compileHTML(from: startDate, to: endDate, in: journal)
                do {
                    try html.write(to: url, atomically: true, encoding: .utf8)
                    isPresented = false
                } catch {
                    errorMessage = "Fehler beim Schreiben der Datei: \(error.localizedDescription)"
                }
                isExporting = false
            case .pdf:
                let html = ExportCompiler.compileHTML(from: startDate, to: endDate, in: journal)
                exporterWrapper.exporter.exportHTMLToPDF(html: html) { result in
                    isExporting = false
                    switch result {
                    case .success(let data):
                        do {
                            try data.write(to: url)
                            isPresented = false
                        } catch {
                            errorMessage = "Fehler beim Schreiben der PDF: \(error.localizedDescription)"
                        }
                    case .failure(let error):
                        errorMessage = "Fehler bei der PDF-Generierung: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}
