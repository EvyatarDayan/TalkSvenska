import SwiftUI
import Speech

enum FilterOption: String, CaseIterable {
    case all = "All"
    case recent = "Recent"
}

struct ManualView: View {
    @StateObject private var manualManager = ManualManager.shared
    @State private var showingAddModal = false
    @State private var selectedSentence: Sentence?
    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .all
    @FocusState private var isSearchFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var showBlurHint = false
    @StateObject private var sessionManager = SessionManager.shared
    // Store hint dismissal state persistently
    @AppStorage("hasShownManualBlurHint") private var hasShownManualBlurHint = false
    
    var filteredSentences: [Sentence] {
        var sentences: [Sentence] = manualManager.manualSentences
        
        // Apply filter
        switch selectedFilter {
        case .all:
            // Keep all sentences
            break
        case .recent:
            // Last 30 items added (most recent first)
            // Since new sentences are appended to the array, the last items are the most recent
            // Take the last 30 items and reverse so most recent is first
            let totalCount = manualManager.manualSentences.count
            let startIndex = max(0, totalCount - 30)
            sentences = Array(manualManager.manualSentences[startIndex..<totalCount])
            sentences = sentences.reversed() // Most recent first
        }
        
        // Apply search text filter
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            sentences = sentences.filter { sentence in
                sentence.swedish.lowercased().contains(lowercasedSearch) ||
                sentence.english.lowercased().contains(lowercasedSearch)
            }
        }
        
        return sentences
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // My list title
            Text("My list")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
                .padding(.top, 20)
                .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 20 : 22)
            
            // Search bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .padding(.leading, 12)
                    
                    TextField("Search...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.vertical, 10)
                        .focused($isSearchFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .padding(.trailing, 12)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.separator), lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            
            // Filter segmented control and count
            HStack {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(maxWidth: .infinity)
                
                // Sentence count
                Text("\(filteredSentences.count) Items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 2)
            .padding(.top, 12)
            
            // + button positioned absolutely
            HStack {
                Spacer()
                Button(action: {
                    showingAddModal = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.blue)
//                        .padding(.top, -60)
                }
            }
            .padding(.horizontal, 30)
            .offset(y: -170)
            
            // Manual sentences content
            if filteredSentences.isEmpty && !searchText.isEmpty {
                // No search results
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No results found")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Try searching with different words")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else if manualManager.manualSentences.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Button(action: {
                        showingAddModal = true
                    }) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                    }
                    
                    Text("No Manual Items")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Tap the + button to add your first manual sentence")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GeometryReader { geometry in
                    List {
                        ForEach(Array(filteredSentences.enumerated()), id: \.element.id) { index, sentence in
                            ManualSentenceCard(
                                sentence: sentence,
                                isFirstItem: index == 0,
                                showBlurHint: index == 0 && showBlurHint,
                                onHintDismiss: {
                                    showBlurHint = false
                                    hasShownManualBlurHint = true
                                }
                            ) {
                                selectedSentence = sentence
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? geometry.size.width * 0.7 : .infinity)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    manualManager.removeManualSentence(sentence)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(Color(.systemGroupedBackground))
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isSearchFocused = false
                }
            }
        }
        .onAppear {
            // Show hint on first item only if not shown before (if we have sentences and no search)
            if !hasShownManualBlurHint && !manualManager.manualSentences.isEmpty && searchText.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !hasShownManualBlurHint {
                        showBlurHint = true
                    }
                }
            } else {
                showBlurHint = false
            }
        }
        .onChange(of: searchText) {
            // Hide hint when searching
            if !searchText.isEmpty {
                showBlurHint = false
            } else if !hasShownManualBlurHint && !manualManager.manualSentences.isEmpty {
                // Show hint again if search is cleared and hint hasn't been shown
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !hasShownManualBlurHint {
                        showBlurHint = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddModal) {
            AddManualSentenceModal()
        }
        .sheet(item: $selectedSentence) { sentence in
            ManualSentenceModalView(
                sentence: sentence,
                manualSentences: manualManager.manualSentences,
                onDismiss: { selectedSentence = nil }
            )
        }
        .overlay(
            Group {
                if (showingAddModal || selectedSentence != nil) && UIDevice.current.userInterfaceIdiom == .pad {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                }
            }
        )
    }
}

struct ManualSentenceCard: View {
    @Environment(\.colorScheme) var colorScheme
    let sentence: Sentence
    let isFirstItem: Bool
    let showBlurHint: Bool
    let onHintDismiss: () -> Void
    let onTap: () -> Void
    @State private var isEnglishRevealed = false
    @State private var hintAnimationScale: CGFloat = 0.8
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .top, spacing: 12) {
                // Sentence content
                VStack(alignment: .leading, spacing: 8) {
                    Text(sentence.swedish)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Text(sentence.english)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .blur(radius: isEnglishRevealed ? 0 : 8)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isEnglishRevealed = true
                            }
                            if showBlurHint {
                                onHintDismiss()
                            }
                        }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Manual icon on the right (similar to favorites "F" icon but with "M")
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Text("M")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .padding(16)
            
            // Hint label positioned on the right side
            if showBlurHint && !isEnglishRevealed {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("See English here")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
                .scaleEffect(hintAnimationScale)
                .padding(.trailing, 70) // Padding to avoid M icon
                .padding(.top, 50) // Position below Swedish text
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        hintAnimationScale = 1.0
                    }
                }
                .onTapGesture {
                    onHintDismiss()
                }
            }
        }
        .background(
            colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

struct AddManualSentenceModal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var manualManager = ManualManager.shared
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var sessionManager = SessionManager.shared
    @State private var swedishText = ""
    @State private var englishText = ""
    @State private var isRecordingSwedish = false
    @State private var isRecordingEnglish = false
    @State private var showDictationHint = false
    @State private var hintAnimationScale: CGFloat = 0.8
    @State private var recordingDots = ""
    @State private var isActuallyRecordingSwedish = false
    @State private var isActuallyRecordingEnglish = false
    @FocusState private var isSwedishFieldFocused: Bool
    @FocusState private var isEnglishFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Swedish section at the top
                    VStack(spacing: 20) {
                        Text("Swedish")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        // Swedish field with buttons
                        VStack(alignment: .leading, spacing: 15) {
                            ZStack(alignment: .trailing) {
                                HStack(spacing: 12) {
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        Spacer()
                                        
                                        // Recording text
                                        if isActuallyRecordingSwedish {
                                            HStack(spacing: 2) {
                                                Text("Recording")
                                                    .font(.body)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.green)
                                                    .lineLimit(1)
                                                Text(recordingDots)
                                                    .font(.body)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.green)
                                                    .frame(width: 15, alignment: .leading)
                                                    .fixedSize()
                                            }
                                            .fixedSize()
                                            .transition(.opacity)
                                        }
                                        
                                        Spacer()
                                        
                                        // Voice button for Swedish
                                        Button(action: {
                                            if isRecordingSwedish {
                                                speechRecognizer.stopRecording()
                                                isRecordingSwedish = false
                                            } else {
                                                speechRecognizer.startRecording(language: "sv-SE") { text in
                                                    swedishText = text
                                                }
                                                isRecordingSwedish = true
                                            }
                                            if showDictationHint {
                                                sessionManager.hasShownManualDictationHint = true
                                                showDictationHint = false
                                            }
                                        }) {
                                            Image(isRecordingSwedish ? "stop" : "voice")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 40, height: 40)
                                        }
                                        .disabled(isRecordingEnglish)
                                    }
                                }
                                
                                // Dictation hint label
                                if showDictationHint && !sessionManager.hasShownManualDictationHint {
                                    HStack(spacing: 4) {
                                        Text("Tap to dictate")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                                    .scaleEffect(hintAnimationScale)
                                    .padding(.trailing, 50) // Position to the right of voice button
                                    .onTapGesture {
                                        sessionManager.hasShownManualDictationHint = true
                                        showDictationHint = false
                                    }
                                }
                            }
                            
                            HStack(spacing: 8) {
                                TextField("Skriv en mening på svenska\nEx: Jag arbetar hemma idag.", text: $swedishText, axis: .vertical)
                                    .lineLimit(4...8)
                                    .font(.title3)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 19)
                                    .focused($isSwedishFieldFocused)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                
                                if !swedishText.isEmpty {
                                    Button(action: {
                                        swedishText = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 20))
                                            .padding(.trailing, 12)
                                    }
                                }
                            }
                            .frame(minHeight: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSwedishFieldFocused ? Color.blue : Color(.systemGray4), lineWidth: isSwedishFieldFocused ? 2 : 1.5)
                            )
                            .animation(.easeInOut(duration: 0.2), value: isSwedishFieldFocused)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 100)
                    .padding(.bottom, 20)
                    
                    // Divider
                    Rectangle()
                        .frame(height: 10)
                        .foregroundColor(Color(.separator))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    
                    // English section at the bottom
                    VStack(spacing: 20) {
                        Text("English")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        // English field with buttons
                        VStack(alignment: .leading, spacing: 15) {
                            HStack(spacing: 12) {
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    Spacer()
                                    
                                    // Recording text
                                    if isActuallyRecordingEnglish {
                                        HStack(spacing: 2) {
                                            Text("Recording")
                                                .font(.body)
                                                .fontWeight(.bold)
                                                .foregroundColor(.green)
                                                .lineLimit(1)
                                            Text(recordingDots)
                                                .font(.body)
                                                .fontWeight(.bold)
                                                .foregroundColor(.green)
                                                .frame(width: 15, alignment: .leading)
                                                .fixedSize()
                                        }
                                        .fixedSize()
                                        .transition(.opacity)
                                    }
                                    
                                    Spacer()
                                    
                                    // Voice button for English
                                    Button(action: {
                                        if isRecordingEnglish {
                                            speechRecognizer.stopRecording()
                                            isRecordingEnglish = false
                                        } else {
                                            speechRecognizer.startRecording(language: "en-US") { text in
                                                englishText = text
                                            }
                                            isRecordingEnglish = true
                                        }
                                    }) {
                                        Image(isRecordingEnglish ? "stop" : "voice")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 40, height: 40)
                                    }
                                    .disabled(isRecordingSwedish)
                                }
                            }
                            
                            HStack(spacing: 8) {
                                TextField("Write the English meaning\nEx: I work from home today.", text: $englishText, axis: .vertical)
                                    .lineLimit(4...8)
                                    .font(.title3)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                    .focused($isEnglishFieldFocused)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                
                                if !englishText.isEmpty {
                                    Button(action: {
                                        englishText = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 20))
                                            .padding(.trailing, 12)
                                    }
                                }
                            }
                            .frame(minHeight: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isEnglishFieldFocused ? Color.blue : Color(.systemGray4), lineWidth: isEnglishFieldFocused ? 2 : 1.5)
                            )
                            .animation(.easeInOut(duration: 0.2), value: isEnglishFieldFocused)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Add Sentence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        speechRecognizer.stopRecording()
                        if !swedishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                           !englishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            let newSentence = Sentence(
                                swedish: swedishText.trimmingCharacters(in: .whitespacesAndNewlines),
                                english: englishText.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                            manualManager.addManualSentence(newSentence)
                            dismiss()
                        }
                    }) {
                        Text("Save")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .disabled(swedishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             englishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                ToolbarItem(placement: .principal) {
                    Image("Talking")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 150 : 100, height: UIDevice.current.userInterfaceIdiom == .pad ? 150 : 100)
                        .padding(.top, 140)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        speechRecognizer.stopRecording()
                        dismiss()
                    }
                }
            }
        }
                    .onAppear {
                // Set up callback for when recording stops automatically
                speechRecognizer.setOnRecordingStopped {
                    isRecordingSwedish = false
                    isRecordingEnglish = false
                }
                
                // Show dictation hint if not shown this session
                if !sessionManager.hasShownManualDictationHint {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if !sessionManager.hasShownManualDictationHint {
                            showDictationHint = true
                            withAnimation(.easeInOut(duration: 0.5)) {
                                hintAnimationScale = 1.0
                            }
                        }
                    }
                }
            }
            .onChange(of: isRecordingSwedish) { oldValue, newValue in
                if newValue {
                    // Wait for actual recording to start
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if speechRecognizer.isRecording && isRecordingSwedish {
                            isActuallyRecordingSwedish = true
                            startRecordingAnimation()
                        }
                    }
                } else {
                    isActuallyRecordingSwedish = false
                    stopRecordingAnimation()
                }
            }
            .onChange(of: isRecordingEnglish) { oldValue, newValue in
                if newValue {
                    // Wait for actual recording to start
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if speechRecognizer.isRecording && isRecordingEnglish {
                            isActuallyRecordingEnglish = true
                            startRecordingAnimation()
                        }
                    }
                } else {
                    isActuallyRecordingEnglish = false
                    stopRecordingAnimation()
                }
            }
            .onChange(of: speechRecognizer.isRecording) { oldValue, newValue in
                if newValue {
                    // Recording actually started
                    if isRecordingSwedish {
                        isActuallyRecordingSwedish = true
                        startRecordingAnimation()
                    } else if isRecordingEnglish {
                        isActuallyRecordingEnglish = true
                        startRecordingAnimation()
                    }
                } else {
                    // Recording stopped
                    isActuallyRecordingSwedish = false
                    isActuallyRecordingEnglish = false
                    stopRecordingAnimation()
                }
            }
            .onDisappear {
                speechRecognizer.stopRecording()
            }
    }
    
    private func startRecordingAnimation() {
        recordingDots = "."
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if !isRecordingSwedish && !isRecordingEnglish {
                timer.invalidate()
                recordingDots = ""
                return
            }
            withAnimation {
                if recordingDots == "." {
                    recordingDots = ".."
                } else {
                    recordingDots = "."
                }
            }
        }
    }
    
    private func stopRecordingAnimation() {
        recordingDots = ""
    }
}

struct EditManualSentenceModal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var sessionManager = SessionManager.shared
    let sentence: Sentence
    let onUpdate: (Sentence) -> Void
    @State private var swedishText: String
    @State private var englishText: String
    @State private var isRecordingSwedish = false
    @State private var isRecordingEnglish = false
    @State private var showDictationHint = false
    @State private var hintAnimationScale: CGFloat = 0.8
    @State private var recordingDots = ""
    @State private var isActuallyRecordingSwedish = false
    @State private var isActuallyRecordingEnglish = false
    @FocusState private var isSwedishFieldFocused: Bool
    @FocusState private var isEnglishFieldFocused: Bool
    
    init(sentence: Sentence, onUpdate: @escaping (Sentence) -> Void) {
        self.sentence = sentence
        self.onUpdate = onUpdate
        _swedishText = State(initialValue: sentence.swedish)
        _englishText = State(initialValue: sentence.english)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Swedish section at the top
                    VStack(spacing: 20) {
                        Text("Swedish")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        // Swedish field with buttons
                        VStack(alignment: .leading, spacing: 15) {
                            ZStack(alignment: .trailing) {
                                HStack(spacing: 12) {
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        Spacer()
                                        
                                        // Recording text
                                        if isActuallyRecordingSwedish {
                                            HStack(spacing: 2) {
                                                Text("Recording")
                                                    .font(.body)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.green)
                                                    .lineLimit(1)
                                                Text(recordingDots)
                                                    .font(.body)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.green)
                                                    .frame(width: 15, alignment: .leading)
                                                    .fixedSize()
                                            }
                                            .fixedSize()
                                            .transition(.opacity)
                                        }
                                        
                                        Spacer()
                                        
                                        // Voice button for Swedish
                                        Button(action: {
                                            if isRecordingSwedish {
                                                speechRecognizer.stopRecording()
                                                isRecordingSwedish = false
                                            } else {
                                                speechRecognizer.startRecording(language: "sv-SE") { text in
                                                    swedishText = text
                                                }
                                                isRecordingSwedish = true
                                            }
                                            if showDictationHint {
                                                sessionManager.hasShownManualDictationHint = true
                                                showDictationHint = false
                                            }
                                        }) {
                                            Image(isRecordingSwedish ? "stop" : "voice")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 40, height: 40)
                                        }
                                        .disabled(isRecordingEnglish)
                                    }
                                }
                                
                                // Dictation hint label
                                if showDictationHint && !sessionManager.hasShownManualDictationHint {
                                    HStack(spacing: 4) {
                                        Text("Tap to dictate")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                                    .scaleEffect(hintAnimationScale)
                                    .padding(.trailing, 50) // Position to the right of voice button
                                    .onTapGesture {
                                        sessionManager.hasShownManualDictationHint = true
                                        showDictationHint = false
                                    }
                                }
                            }
                            
                            HStack(spacing: 8) {
                                TextField("Skriv en mening på svenska\nEx: Jag arbetar hemma idag.", text: $swedishText, axis: .vertical)
                                    .lineLimit(4...8)
                                    .font(.title3)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 19)
                                    .focused($isSwedishFieldFocused)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                
                                if !swedishText.isEmpty {
                                    Button(action: {
                                        swedishText = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 20))
                                            .padding(.trailing, 12)
                                    }
                                }
                            }
                            .frame(minHeight: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSwedishFieldFocused ? Color.blue : Color(.systemGray4), lineWidth: isSwedishFieldFocused ? 2 : 1.5)
                            )
                            .animation(.easeInOut(duration: 0.2), value: isSwedishFieldFocused)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 100)
                    .padding(.bottom, 20)
                    
                    // Divider
                    Rectangle()
                        .frame(height: 10)
                        .foregroundColor(Color(.separator))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    
                    // English section at the bottom
                    VStack(spacing: 20) {
                        Text("English")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        // English field with buttons
                        VStack(alignment: .leading, spacing: 15) {
                            HStack(spacing: 12) {
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    Spacer()
                                    
                                    // Recording text
                                    if isActuallyRecordingEnglish {
                                        HStack(spacing: 2) {
                                            Text("Recording")
                                                .font(.body)
                                                .fontWeight(.bold)
                                                .foregroundColor(.green)
                                                .lineLimit(1)
                                            Text(recordingDots)
                                                .font(.body)
                                                .fontWeight(.bold)
                                                .foregroundColor(.green)
                                                .frame(width: 15, alignment: .leading)
                                                .fixedSize()
                                        }
                                        .fixedSize()
                                        .transition(.opacity)
                                    }
                                    
                                    Spacer()
                                    
                                    // Voice button for English
                                    Button(action: {
                                        if isRecordingEnglish {
                                            speechRecognizer.stopRecording()
                                            isRecordingEnglish = false
                                        } else {
                                            speechRecognizer.startRecording(language: "en-US") { text in
                                                englishText = text
                                            }
                                            isRecordingEnglish = true
                                        }
                                    }) {
                                        Image(isRecordingEnglish ? "stop" : "voice")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 40, height: 40)
                                    }
                                    .disabled(isRecordingSwedish)
                                }
                            }
                            
                            HStack(spacing: 8) {
                                TextField("Write the English meaning\nEx: I work from home today.", text: $englishText, axis: .vertical)
                                    .lineLimit(4...8)
                                    .font(.title3)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                    .focused($isEnglishFieldFocused)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                
                                if !englishText.isEmpty {
                                    Button(action: {
                                        englishText = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 20))
                                            .padding(.trailing, 12)
                                    }
                                }
                            }
                            .frame(minHeight: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isEnglishFieldFocused ? Color.blue : Color(.systemGray4), lineWidth: isEnglishFieldFocused ? 2 : 1.5)
                            )
                            .animation(.easeInOut(duration: 0.2), value: isEnglishFieldFocused)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Sentence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        speechRecognizer.stopRecording()
                        if !swedishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                           !englishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            let updatedSentence = Sentence(
                                id: sentence.id,
                                swedish: swedishText.trimmingCharacters(in: .whitespacesAndNewlines),
                                english: englishText.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                            onUpdate(updatedSentence)
                            dismiss()
                        }
                    }) {
                        Text("Save")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .disabled(swedishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             englishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                ToolbarItem(placement: .principal) {
                    Image("Talking")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 150 : 100, height: UIDevice.current.userInterfaceIdiom == .pad ? 150 : 100)
                        .padding(.top, 150)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        speechRecognizer.stopRecording()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Set up callback for when recording stops automatically
            speechRecognizer.setOnRecordingStopped {
                isRecordingSwedish = false
                isRecordingEnglish = false
            }
            
            // Show dictation hint if not shown this session
            if !sessionManager.hasShownManualDictationHint {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !sessionManager.hasShownManualDictationHint {
                        showDictationHint = true
                        withAnimation(.easeInOut(duration: 0.5)) {
                            hintAnimationScale = 1.0
                        }
                    }
                }
            }
        }
        .onChange(of: isRecordingSwedish) { oldValue, newValue in
            if newValue {
                // Wait for actual recording to start
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if speechRecognizer.isRecording && isRecordingSwedish {
                        isActuallyRecordingSwedish = true
                        startRecordingAnimation()
                    }
                }
            } else {
                isActuallyRecordingSwedish = false
                stopRecordingAnimation()
            }
        }
        .onChange(of: isRecordingEnglish) { oldValue, newValue in
            if newValue {
                // Wait for actual recording to start
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if speechRecognizer.isRecording && isRecordingEnglish {
                        isActuallyRecordingEnglish = true
                        startRecordingAnimation()
                    }
                }
            } else {
                isActuallyRecordingEnglish = false
                stopRecordingAnimation()
            }
        }
        .onChange(of: speechRecognizer.isRecording) { oldValue, newValue in
            if newValue {
                // Recording actually started
                if isRecordingSwedish {
                    isActuallyRecordingSwedish = true
                    startRecordingAnimation()
                } else if isRecordingEnglish {
                    isActuallyRecordingEnglish = true
                    startRecordingAnimation()
                }
            } else {
                // Recording stopped
                isActuallyRecordingSwedish = false
                isActuallyRecordingEnglish = false
                stopRecordingAnimation()
            }
        }
        .onDisappear {
            speechRecognizer.stopRecording()
        }
    }
    
    private func startRecordingAnimation() {
        recordingDots = "."
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if !isActuallyRecordingSwedish && !isActuallyRecordingEnglish {
                timer.invalidate()
                recordingDots = ""
                return
            }
            withAnimation {
                if recordingDots == "." {
                    recordingDots = ".."
                } else {
                    recordingDots = "."
                }
            }
        }
    }
    
    private func stopRecordingAnimation() {
        recordingDots = ""
    }
}

// MARK: - ManualManager
class ManualManager: ObservableObject {
    static let shared = ManualManager()
    
    @Published var manualSentences: [Sentence] = []
    
    private init() {
        loadManualSentences()
    }
    
    func addManualSentence(_ sentence: Sentence) {
        // Ensure the sentence has a dateCreated
        let sentenceWithDate = Sentence(
            id: sentence.id,
            swedish: sentence.swedish,
            english: sentence.english,
            dateCreated: sentence.dateCreated ?? Date()
        )
        manualSentences.append(sentenceWithDate)
        saveManualSentences()
    }
    
    func removeManualSentence(_ sentence: Sentence) {
        manualSentences.removeAll { $0.id == sentence.id }
        saveManualSentences()
    }
    
    func updateManualSentence(_ updatedSentence: Sentence) {
        if let index = manualSentences.firstIndex(where: { $0.id == updatedSentence.id }) {
            // Preserve the original dateCreated when updating
            let originalSentence = manualSentences[index]
            let sentenceWithDate = Sentence(
                id: updatedSentence.id,
                swedish: updatedSentence.swedish,
                english: updatedSentence.english,
                dateCreated: updatedSentence.dateCreated ?? originalSentence.dateCreated ?? Date()
            )
            manualSentences[index] = sentenceWithDate
            saveManualSentences()
        }
    }
    
    private func saveManualSentences() {
        do {
            let encoded = try JSONEncoder().encode(manualSentences)
            UserDefaults.standard.set(encoded, forKey: "manualSentences")
        } catch {
            print("❌ Failed to save manual sentences: \(error)")
        }
    }
    
    private func loadManualSentences() {
        if let data = UserDefaults.standard.data(forKey: "manualSentences") {
            do {
                let decoded = try JSONDecoder().decode([Sentence].self, from: data)
                manualSentences = decoded
            } catch {
                print("❌ Failed to load manual sentences: \(error)")
                manualSentences = []
            }
        }
    }
    
    func clearAllManualSentences() {
        manualSentences = []
        UserDefaults.standard.removeObject(forKey: "manualSentences")
        print("🗑️ Cleared all manual sentences")
    }
    
    // Export manual sentences as JSON string for backup
    func exportManualSentences() -> String? {
        do {
            let encoded = try JSONEncoder().encode(manualSentences)
            return String(data: encoded, encoding: .utf8)
        } catch {
            print("❌ Failed to export manual sentences: \(error)")
            return nil
        }
    }
    
    // Import manual sentences from JSON string
    func importManualSentences(from jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else {
            print("❌ Failed to convert JSON string to data")
            return false
        }
        
        do {
            let decoded = try JSONDecoder().decode([Sentence].self, from: data)
            manualSentences = decoded
            saveManualSentences()
            print("✅ Successfully imported \(decoded.count) manual sentences")
            return true
        } catch {
            print("❌ Failed to import manual sentences: \(error)")
            return false
        }
    }
}

// MARK: - ManualSentenceModalView
struct ManualSentenceModalView: View {
    let initialSentence: Sentence
    let manualSentences: [Sentence]
    let onDismiss: () -> Void
    
    @State private var currentSentence: Sentence
    @State private var showTranslation = false
    @State private var isRefreshing = false
    @State private var currentIndex: Int
    @State private var showingEditModal = false
    @StateObject private var audioManager = AudioManager()
    @StateObject private var manualManager = ManualManager.shared
    
    init(sentence: Sentence, manualSentences: [Sentence], onDismiss: @escaping () -> Void) {
        self.initialSentence = sentence
        self.manualSentences = manualSentences
        self.onDismiss = onDismiss
        self._currentSentence = State(initialValue: sentence)
        
        // Find the index of the initial sentence
        if let index = manualSentences.firstIndex(where: { $0.id == sentence.id }) {
            self._currentIndex = State(initialValue: index)
        } else {
            self._currentIndex = State(initialValue: 0)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main layout - Swedish and English sections at top, buttons below
                VStack(spacing: 0) {
                    // Swedish section at the top
                    VStack(spacing: 20) {
                        Text("Svenska")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .scaleEffect(isRefreshing ? 0.9 : 1.0)
                            .opacity(isRefreshing ? 0.5 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                        
                        // Swedish sentence
                        Text(currentSentence.swedish)
                            .font(.title)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .opacity(isRefreshing ? 0.3 : 1.0)
                            .scaleEffect(isRefreshing ? 0.85 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                    }
                    .padding(.top, 130)
                    .padding(.bottom, 20)
                    
                    // Divider - centered vertically
                    Spacer()
                    
                    Rectangle()
                        .frame(height: 10)
                        .foregroundColor(Color(.separator))
                        .padding(.horizontal, 20)
                        .scaleEffect(isRefreshing ? 0.9 : 1.0)
                        .opacity(isRefreshing ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                    
                    Spacer()
                    
                    // English translation area - centered between divider and buttons
                    VStack {
                        if !showTranslation {
                            // Show button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    showTranslation = true
                                }
                            }) {
                                HStack {
                                    Text("English")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 50)
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                            .scaleEffect(isRefreshing ? 0.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0),
                                removal: .scale(scale: 0)
                            ))
                        }
                    }
                    .frame(height: 120)
                    
                    Spacer()
                    
                    // Buttons section at the bottom
                    HStack {
                        // Previous button
                        Button(action: {
                            if currentIndex > 0 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isRefreshing = true
                                    showTranslation = false
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    currentIndex -= 1
                                    currentSentence = manualSentences[currentIndex]
                                    
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isRefreshing = false
                                    }
                                }
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 60, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(.separator), lineWidth: 1)
                                        )
                                )
                                .offset(x: isRefreshing ? -20 : 0)
                                .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                        }
                        .scaleEffect(isRefreshing ? 0.9 : 1.0)
                        .opacity(isRefreshing ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                        
                        Spacer()
                        
                        // Sound button
                        Button(action: {
                            audioManager.playAudio()
                        }) {
                            Group {
                                if audioManager.isPlaying {
                                    Image(systemName: "pause.circle.fill")
                                        .font(.system(size: 40, weight: .medium))
                                        .foregroundColor(audioManager.isAudioReady ? .blue : .gray)
                                } else {
                                    Image("audio-headphone")
                                        .resizable()
                                        .renderingMode(.template)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(audioManager.isAudioReady ? .blue : .gray)
                                }
                            }
                            .frame(width: 60, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(.separator), lineWidth: 1)
                                    )
                            )
                        }
                        .disabled(audioManager.isPlaying || !audioManager.isAudioReady)
                        .scaleEffect(isRefreshing ? 0.9 : 1.0)
                        .opacity(isRefreshing ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                        
                        Spacer()
                        
                        // Next button
                        Button(action: {
                            if currentIndex < manualSentences.count - 1 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isRefreshing = true
                                    showTranslation = false
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    currentIndex += 1
                                    currentSentence = manualSentences[currentIndex]
                                    
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isRefreshing = false
                                    }
                                }
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 60, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(.separator), lineWidth: 1)
                                        )
                                )
                                .offset(x: isRefreshing ? 20 : 0)
                                .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                        }
                        .scaleEffect(isRefreshing ? 0.9 : 1.0)
                        .opacity(isRefreshing ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
                
                // English translation overlay - positioned between divider and buttons
                if showTranslation {
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Text("English")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .scaleEffect(isRefreshing ? 0.9 : 1.0)
                                .opacity(isRefreshing ? 0.5 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                            
                            Text(currentSentence.english)
                                .font(.title)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .scaleEffect(isRefreshing ? 0.85 : 1.0)
                                .opacity(isRefreshing ? 0.3 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 230)     // English translation position
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .leading)),
                            removal: .opacity
                        ))
                        
                        Spacer()
                    }
                    .zIndex(1)
                }
            }
            .navigationTitle("Manual")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingEditModal = true
                    }) {
                        Text("Edit")
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Image("Talking")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 150 : 100, height: UIDevice.current.userInterfaceIdiom == .pad ? 150 : 100)
                        .scaleEffect(isRefreshing ? 0.9 : 1.0)
                        .opacity(isRefreshing ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                        .padding(.top, 150)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        onDismiss()
                    }) {
                        Text("Close")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 8)
                    .scaleEffect(isRefreshing ? 0.9 : 1.0)
                    .opacity(isRefreshing ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                }
            }
            .sheet(isPresented: $showingEditModal) {
                EditManualSentenceModal(sentence: currentSentence) { updatedSentence in
                    manualManager.updateManualSentence(updatedSentence)
                    // Update current sentence and refresh the list
                    currentSentence = updatedSentence
                    // Update the index if needed
                    if let newIndex = manualManager.manualSentences.firstIndex(where: { $0.id == updatedSentence.id }) {
                        currentIndex = newIndex
                    }
                }
            }
        }
        .onAppear {
            audioManager.generateAudio(for: currentSentence.swedish)
        }
        .onChange(of: currentSentence) {
            audioManager.generateAudio(for: currentSentence.swedish)
        }
        .onDisappear {
            audioManager.cleanupAudio()
        }
    }
}

// MARK: - SpeechRecognizer
class SpeechRecognizer: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    
    private var currentCompletion: ((String) -> Void)?
    private var onRecordingStopped: (() -> Void)?
    
    override init() {
        super.init()
    }
    
    func startRecording(language: String, completion: @escaping (String) -> Void) {
        // Don't start if already recording
        if isRecording {
            print("Already recording, stopping first")
            stopRecording()
            return
        }
        
        // Store the completion callback
        self.currentCompletion = completion
        
        // Request authorization
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.startSimpleRecording(language: language)
                case .denied:
                    print("Speech recognition authorization denied - user denied access")
                case .restricted:
                    print("Speech recognition authorization restricted")
                case .notDetermined:
                    print("Speech recognition authorization not determined")
                @unknown default:
                    print("Unknown authorization status")
                }
            }
        }
    }
    
    private func startSimpleRecording(language: String) {
        // Create speech recognizer for the specified language
        guard let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: language)) else {
            print("Speech recognizer not available for language: \(language)")
            return
        }
        
        // Create recognition request
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition task
        let recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                let transcribedText = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self?.transcribedText = transcribedText
                    self?.currentCompletion?(transcribedText)
                }
                
                // If this is the final result (user stopped talking), auto-stop recording
                if result.isFinal {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // 0.5 second delay
                        self?.stopRecording()
                    }
                }
            }
            
            if error != nil {
                self?.stopRecording()
            }
        }
        
        // Set up audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Create audio engine
            let audioEngine = AVAudioEngine()
            let inputNode = audioEngine.inputNode
            
            // Use the input node's native format
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            // Start audio engine
            audioEngine.prepare()
            try audioEngine.start()
            
            // Store references for cleanup
            self.audioEngine = audioEngine
            self.recognitionRequest = recognitionRequest
            self.recognitionTask = recognitionTask
            
            DispatchQueue.main.async {
                self.isRecording = true
            }
            
        } catch {
            print("Error starting speech recognition: \(error)")
            self.stopRecording()
        }
    }
    
    // Store references for cleanup
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    func stopRecording() {
        // Stop audio engine
        if let audioEngine = audioEngine, audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // End recognition
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Clean up
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        currentCompletion = nil
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error deactivating audio session: \(error)")
        }
        
        DispatchQueue.main.async {
            self.isRecording = false
            self.onRecordingStopped?()
        }
    }
    
    // Callback to notify when recording stops automatically
    func setOnRecordingStopped(_ callback: @escaping () -> Void) {
        self.onRecordingStopped = callback
    }
}
