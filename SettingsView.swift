import SwiftUI
import UniformTypeIdentifiers

private enum SettingsFileImportDestination {
    case manual
    case favorites
}

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.colorScheme) var colorScheme

    @State private var showingHelpSupport = false
    @State private var showingAboutStudio = false
    @State private var showingScheduleSettings = false
    @State private var showingClearHistoryConfirmation = false
    @State private var showingClearFavoritesConfirmation = false
    @State private var showingClearManualConfirmation = false
    @State private var showingLearningTips = false
    @State private var showingTermsPrivacy = false
    @State private var showingExportManualSheet = false
    @State private var fileImportDestination: SettingsFileImportDestination?
    @State private var isFileImporterPresented = false
    @State private var showingManualImportReplaceConfirmation = false
    @State private var pendingManualImportSentences: [Sentence]?
    /// Snapshot of list size when replace confirmation is shown (message text).
    @State private var pendingManualReplacePreviousListCount: Int = 0
    @State private var manualImportOutcomeMessage: String?
    @State private var showingExportFavoritesSheet = false
    @State private var showingFavoritesImportReplaceConfirmation = false
    @State private var pendingFavoriteImportSentences: [Sentence]?
    @State private var pendingFavoritesReplacePreviousListCount: Int = 0
    @State private var favoritesImportOutcomeMessage: String?
    @State private var exportData: [Any] = []
    @State private var isExporting = false
    @State private var exportFileName = ""
    @StateObject private var historyManager = TestHistoryManager.shared
    @StateObject private var favoriteManager = FavoriteManager.shared
    @StateObject private var manualManager = ManualManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Settings title
            HStack(spacing: 0) {
                Text("Sett")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
                Text("ings")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
            }
                .padding(.top, 20)
            .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 20 : 20)
            
            // Settings content
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        // MODE Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("MODE")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .padding(.horizontal, 20)
                            
                    // Dark Mode
                            SettingOptionCard(
                                icon: "moon.fill",
                                iconColor: .purple,
                                title: "Dark Mode",
                                description: "Enable dark mode",
                                showToggle: true,
                                isOn: $isDarkMode,
                                showChevron: false
                            )
                    }
                        
                        // SCHEDULE Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SCHEDULE")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .padding(.horizontal, 20)
                    
                            // Schedule Settings Button
                    Button(action: {
                                showingScheduleSettings = true
                    }) {
                                SettingOptionCard(
                                    icon: "clock.fill",
                                    iconColor: .orange,
                                    title: "Schedule Notifications",
                                    description: "Configure notification time",
                                    showToggle: false,
                                    isOn: .constant(false),
                                    showChevron: true
                                )
                            }
                        }
                        
                        // LEARNING Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("LEARNING")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .padding(.horizontal, 20)
                            
                            // Learning Tips
                            Button(action: {
                                showingLearningTips = true
                            }) {
                                SettingOptionCard(
                                    icon: "lightbulb.fill",
                                    iconColor: .yellow,
                                    title: "Learning Tips",
                                    description: "Effective learning strategies",
                                    showToggle: false,
                                    isOn: .constant(false),
                                    showChevron: true
                                )
                            }
                        }
                        
                        // SUPPORT Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SUPPORT")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .padding(.horizontal, 20)
                            
                            // Grouped Support Items
                            VStack(spacing: 0) {
                                // Help & Support
                                Button(action: {
                                    showingHelpSupport = true
                                }) {
                                    SettingOptionCard(
                                        icon: "questionmark.circle.fill",
                                        iconColor: .blue,
                                        title: "Help & Support",
                                        description: "Get help and contact support",
                                        showToggle: false,
                                        isOn: .constant(false),
                                        showChevron: true,
                                        isGrouped: true,
                                        isFirstInGroup: true,
                                        isLastInGroup: false
                                    )
                                }
                                
                                Divider()
                                    .padding(.leading, 60)
                                    .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray4))
                    
                    // Terms & Privacy
                    Button(action: {
                        showingTermsPrivacy = true
                    }) {
                                    SettingOptionCard(
                                        icon: "doc.text.fill",
                                        iconColor: .blue,
                                        title: "Terms & Privacy",
                                        description: "View terms and privacy policy",
                                        showToggle: false,
                                        isOn: .constant(false),
                                        showChevron: true,
                                        isGrouped: true,
                                        isFirstInGroup: false,
                                        isLastInGroup: false
                                    )
                                }
                                
                                Divider()
                                    .padding(.leading, 60)
                                    .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray4))
                                
                                // About
                                Button(action: {
                                    showingAboutStudio = true
                                }) {
                                    SettingOptionCard(
                                        icon: "info.circle.fill",
                                        iconColor: .blue,
                                        title: "About",
                                        description: "App version and information",
                                        showToggle: false,
                                        isOn: .constant(false),
                                        showChevron: true,
                                        isGrouped: true,
                                        isFirstInGroup: false,
                                        isLastInGroup: true
                                    )
                                }
                            }
                    .background(
                        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            .padding(.horizontal, 20)
                        }
                        
                        // EXPORT DATA Section
                        exportDataSection
                        
                        // CLEAR HISTORY Section
                        clearHistorySection
                    }
                        }
                    }
        }
        .overlay(exportLoadingOverlay)
        .sheet(isPresented: $showingLearningTips) {
            LearningTipsView()
        }
        .sheet(isPresented: $showingHelpSupport) {
            HelpSupportView()
        }
        .sheet(isPresented: $showingTermsPrivacy) {
            TermsPrivacyView()
        }
        .sheet(isPresented: $showingExportManualSheet) {
            if !exportData.isEmpty {
                ShareSheet(activityItems: exportData)
            }
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            let destination = fileImportDestination
            fileImportDestination = nil
            switch destination {
            case .manual:
                handleManualImportPickerResult(result)
            case .favorites:
                handleFavoritesImportPickerResult(result)
            case .none:
                break
            }
        }
        .alert("Replace manual list?", isPresented: $showingManualImportReplaceConfirmation) {
            Button("Cancel", role: .cancel) {
                pendingManualImportSentences = nil
                pendingManualReplacePreviousListCount = 0
            }
            Button("Replace", role: .destructive) {
                if let sentences = pendingManualImportSentences {
                    let count = sentences.count
                    manualManager.replaceManualSentences(with: sentences)
                    pendingManualImportSentences = nil
                    pendingManualReplacePreviousListCount = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        manualImportOutcomeMessage = "Imported \(count) sentence\(count == 1 ? "" : "s")."
                    }
                }
            }
        } message: {
            if let imported = pendingManualImportSentences {
                Text("Your current list (\(pendingManualReplacePreviousListCount) items) will be replaced with \(imported.count) items from the file. Order and formatting from the backup are preserved.")
            }
        }
        .alert("Manual import", isPresented: Binding(
            get: { manualImportOutcomeMessage != nil },
            set: { if !$0 { manualImportOutcomeMessage = nil } }
        )) {
            Button("OK", role: .cancel) {
                manualImportOutcomeMessage = nil
            }
        } message: {
            Text(manualImportOutcomeMessage ?? "")
        }
        .alert("Replace favorites?", isPresented: $showingFavoritesImportReplaceConfirmation) {
            Button("Cancel", role: .cancel) {
                pendingFavoriteImportSentences = nil
                pendingFavoritesReplacePreviousListCount = 0
            }
            Button("Replace", role: .destructive) {
                if let sentences = pendingFavoriteImportSentences {
                    let count = sentences.count
                    favoriteManager.replaceFavorites(with: sentences)
                    pendingFavoriteImportSentences = nil
                    pendingFavoritesReplacePreviousListCount = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        favoritesImportOutcomeMessage = "Imported \(count) favorite\(count == 1 ? "" : "s")."
                    }
                }
            }
        } message: {
            if let imported = pendingFavoriteImportSentences {
                Text("Your current favorites (\(pendingFavoritesReplacePreviousListCount) items) will be replaced with \(imported.count) items from the file. Order from the backup is preserved.")
            }
        }
        .alert("Favorites import", isPresented: Binding(
            get: { favoritesImportOutcomeMessage != nil },
            set: { if !$0 { favoritesImportOutcomeMessage = nil } }
        )) {
            Button("OK", role: .cancel) {
                favoritesImportOutcomeMessage = nil
            }
        } message: {
            Text(favoritesImportOutcomeMessage ?? "")
        }
        .sheet(isPresented: $showingExportFavoritesSheet) {
            if !exportData.isEmpty {
                ShareSheet(activityItems: exportData)
            }
        }
        .sheet(isPresented: $showingAboutStudio) {
            AboutStudioView()
        }
        .sheet(isPresented: $showingScheduleSettings) {
            NavigationView {
                ScheduleView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingScheduleSettings = false
                            }
                        }
                    }
            }
        }
        .alert("Are you sure?", isPresented: $showingClearHistoryConfirmation) {
            Button("No", role: .cancel) {}
            Button("Yes", role: .destructive) {
                historyManager.clearAllHistory()
            }
        } message: {
            Text("All test history will be deleted forever.")
        }
        .alert("Are you sure?", isPresented: $showingClearFavoritesConfirmation) {
            Button("No", role: .cancel) {}
            Button("Yes", role: .destructive) {
                favoriteManager.clearAllFavorites()
            }
        } message: {
            Text("All favorite sentences will be deleted forever.")
        }
        .alert("Are you sure?", isPresented: $showingClearManualConfirmation) {
            Button("No", role: .cancel) {}
            Button("Yes", role: .destructive) {
                manualManager.clearAllManualSentences()
            }
        } message: {
            Text("All manual sentences will be deleted forever.")
        }
        .overlay(
            Group {
                if (showingLearningTips || showingHelpSupport || showingTermsPrivacy || showingAboutStudio || showingScheduleSettings) && UIDevice.current.userInterfaceIdiom == .pad {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                }
            }
        )
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var exportLoadingOverlay: some View {
        Group {
            if isExporting {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text("Preparing export...")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                    )
                    .shadow(radius: 10)
                }
            }
        }
    }
    
    @ViewBuilder
    private var exportDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EXPORT DATA")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 20)
            
            // Grouped Export Items
            VStack(spacing: 0) {
                // Manual backup: export or import JSON (same format; order & rich text preserved)
                Menu {
                    Button {
                        exportManualSentences()
                    } label: {
                        Label("Export to file", systemImage: "square.and.arrow.up")
                    }
                    .disabled(manualManager.manualSentences.isEmpty)
                    
                    Button {
                        presentSettingsFileImporter(.manual)
                    } label: {
                        Label("Import from file", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    SettingOptionCard(
                        icon: "arrow.up.arrow.down.circle.fill",
                        iconColor: .blue,
                        title: "Export/Import Manual",
                        description: "Export or import a backup file",
                        showToggle: false,
                        isOn: .constant(false),
                        showChevron: true,
                        isGrouped: true,
                        isFirstInGroup: true,
                        isLastInGroup: false
                    )
                }
                .buttonStyle(.plain)
                
                Divider()
                    .padding(.leading, 60)
                    .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray4))
                
                // Favorites backup: export or import JSON
                Menu {
                    Button {
                        exportFavorites()
                    } label: {
                        Label("Export to file", systemImage: "square.and.arrow.up")
                    }
                    .disabled(favoriteManager.favorites.isEmpty)
                    
                    Button {
                        presentSettingsFileImporter(.favorites)
                    } label: {
                        Label("Import from file", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    SettingOptionCard(
                        icon: "arrow.up.arrow.down.circle.fill",
                        iconColor: .blue,
                        title: "Export/Import Favorites",
                        description: "Export or import a favorites backup file",
                        showToggle: false,
                        isOn: .constant(false),
                        showChevron: true,
                        isGrouped: true,
                        isFirstInGroup: false,
                        isLastInGroup: true
                    )
                }
                .buttonStyle(.plain)
            }
            .background(
                colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
            )
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private var clearHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CLEAR HISTORY")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 20)
            
            // Grouped Clear History Items
            VStack(spacing: 0) {
                // Clear Test History Button
                Button(action: {
                    showingClearHistoryConfirmation = true
                }) {
                    SettingOptionCard(
                        icon: "trash.fill",
                        iconColor: .red,
                        title: "Clear Test History",
                        description: "Delete all test history",
                        showToggle: false,
                        isOn: .constant(false),
                        showChevron: false,
                        isGrouped: true,
                        isFirstInGroup: true,
                        isLastInGroup: false
                    )
                }
                
                Divider()
                    .padding(.leading, 60)
                    .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray4))
                
                // Clear Favorites History Button
                Button(action: {
                    showingClearFavoritesConfirmation = true
                }) {
                    SettingOptionCard(
                        icon: "trash.fill",
                        iconColor: .red,
                        title: "Clear Favorites History",
                        description: "Delete all favorites",
                        showToggle: false,
                        isOn: .constant(false),
                        showChevron: false,
                        isGrouped: true,
                        isFirstInGroup: false,
                        isLastInGroup: false
                    )
                }
                
                Divider()
                    .padding(.leading, 60)
                    .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray4))
                
                // Clear Manual History Button
                Button(action: {
                    showingClearManualConfirmation = true
                }) {
                    SettingOptionCard(
                        icon: "trash.fill",
                        iconColor: .red,
                        title: "Clear Manual History",
                        description: "Delete all manual sentences",
                        showToggle: false,
                        isOn: .constant(false),
                        showChevron: false,
                        isGrouped: true,
                        isFirstInGroup: false,
                        isLastInGroup: true
                    )
                }
            }
            .background(
                colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
            )
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Manual import / export
    
    /// One shared `fileImporter` — duplicate `.fileImporter` modifiers on the same view often leave only the last one active. Presentation is deferred so the `Menu` can dismiss before the system document UI appears.
    private func presentSettingsFileImporter(_ destination: SettingsFileImportDestination) {
        fileImportDestination = destination
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isFileImporterPresented = true
        }
    }
    
    private func handleManualImportPickerResult(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            manualImportOutcomeMessage = "Could not open file: \(error.localizedDescription)"
        case .success(let urls):
            guard let url = urls.first else {
                manualImportOutcomeMessage = "No file was selected."
                return
            }
            let gotAccess = url.startAccessingSecurityScopedResource()
            defer {
                if gotAccess { url.stopAccessingSecurityScopedResource() }
            }
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode([Sentence].self, from: data)
                if manualManager.manualSentences.isEmpty {
                    manualManager.replaceManualSentences(with: decoded)
                    manualImportOutcomeMessage = "Imported \(decoded.count) sentence\(decoded.count == 1 ? "" : "s")."
                } else {
                    pendingManualReplacePreviousListCount = manualManager.manualSentences.count
                    pendingManualImportSentences = decoded
                    showingManualImportReplaceConfirmation = true
                }
            } catch {
                manualImportOutcomeMessage = "This file is not a valid TalkSvenska manual backup (JSON)."
            }
        }
    }
    
    private func handleFavoritesImportPickerResult(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            favoritesImportOutcomeMessage = "Could not open file: \(error.localizedDescription)"
        case .success(let urls):
            guard let url = urls.first else {
                favoritesImportOutcomeMessage = "No file was selected."
                return
            }
            let gotAccess = url.startAccessingSecurityScopedResource()
            defer {
                if gotAccess { url.stopAccessingSecurityScopedResource() }
            }
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode([Sentence].self, from: data)
                if favoriteManager.favorites.isEmpty {
                    favoriteManager.replaceFavorites(with: decoded)
                    favoritesImportOutcomeMessage = "Imported \(decoded.count) favorite\(decoded.count == 1 ? "" : "s")."
                } else {
                    pendingFavoritesReplacePreviousListCount = favoriteManager.favorites.count
                    pendingFavoriteImportSentences = decoded
                    showingFavoritesImportReplaceConfirmation = true
                }
            } catch {
                favoritesImportOutcomeMessage = "This file is not a valid TalkSvenska favorites backup (JSON)."
            }
        }
    }
    
    // MARK: - Export Functions
    
    private func exportManualSentences() {
        isExporting = true
        DispatchQueue.global(qos: .userInitiated).async {
            if let jsonString = manualManager.exportManualSentences() {
                let fileName = "TalkSvenska_Manual_\(Date().timeIntervalSince1970).json"
                if let fileURL = createTempFile(content: jsonString, fileName: fileName) {
                    DispatchQueue.main.async {
                        exportData = [fileURL]
                        exportFileName = fileName
                        isExporting = false
                        showingExportManualSheet = true
                    }
                } else {
                    DispatchQueue.main.async {
                        isExporting = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    isExporting = false
                }
            }
        }
    }
    
    private func exportFavorites() {
        isExporting = true
        DispatchQueue.global(qos: .userInitiated).async {
            if let jsonString = favoriteManager.exportFavorites() {
                let fileName = "TalkSvenska_Favorites_\(Date().timeIntervalSince1970).json"
                if let fileURL = createTempFile(content: jsonString, fileName: fileName) {
                    DispatchQueue.main.async {
                        exportData = [fileURL]
                        exportFileName = fileName
                        isExporting = false
                        showingExportFavoritesSheet = true
                    }
                } else {
                    DispatchQueue.main.async {
                        isExporting = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    isExporting = false
                }
            }
        }
    }
    
    // Helper function to create temporary file
    private func createTempFile(content: String, fileName: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            // Use atomically: false for better performance on large files
            try content.write(to: fileURL, atomically: false, encoding: .utf8)
            
            // Ensure file is accessible
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                print("❌ File was not created at path: \(fileURL.path)")
                return nil
            }
            
            return fileURL
        } catch {
            print("❌ Failed to create temp file: \(error)")
            return nil
        }
    }
}

struct SettingOptionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let showToggle: Bool
    @Binding var isOn: Bool
    let showChevron: Bool
    var onToggle: ((Bool) -> Void)? = nil
    var isGrouped: Bool = false
    var isFirstInGroup: Bool = false
    var isLastInGroup: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor)
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .medium))
            }
            
            // Title and Description
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Toggle or Chevron
            if showToggle {
                Toggle("", isOn: Binding(
                    get: { isOn },
                    set: { newValue in
                        isOn = newValue
                        onToggle?(newValue)
                    }
                ))
                .labelsHidden()
                .frame(width: 44, height: 26)
                .scaleEffect(0.75)
            } else if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            isGrouped ? Color.clear : (colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        )
        .cornerRadius(isGrouped ? 0 : 12)
        .shadow(color: isGrouped ? Color.clear : Color.black.opacity(0.1), radius: isGrouped ? 0 : 2, x: 0, y: isGrouped ? 0 : 1)
        .padding(.horizontal, isGrouped ? 0 : 20)
    }
}

// MARK: - FileActivityItemSource
class FileActivityItemSource: NSObject, UIActivityItemSource {
    let fileURL: URL
    let fileName: String
    
    init(fileURL: URL, fileName: String) {
        self.fileURL = fileURL
        self.fileName = fileName
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return fileURL
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return fileURL
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return fileName
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "public.json"
    }
}

// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Wrap file URLs in FileActivityItemSource to prevent blocking
        let wrappedItems = activityItems.map { item in
            if let url = item as? URL {
                let fileName = url.lastPathComponent
                return FileActivityItemSource(fileURL: url, fileName: fileName) as Any
            }
            return item
        }
        
        let controller = UIActivityViewController(activityItems: wrappedItems, applicationActivities: nil)
        
        // Configure for iPad
        if let popover = controller.popoverPresentationController {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                popover.sourceView = window.rootViewController?.view
                popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
}
