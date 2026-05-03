import SwiftUI
import AVFoundation
import AudioToolbox

struct TestWordItem: Identifiable, Equatable {
    let id: UUID
    let word: TestWord
    var userAnswer: String
    var isAnswered: Bool
    var isCorrect: Bool
    
    init(word: TestWord, userAnswer: String = "", isAnswered: Bool = false, isCorrect: Bool = false) {
        self.id = UUID()
        self.word = word
        self.userAnswer = userAnswer
        self.isAnswered = isAnswered
        self.isCorrect = isCorrect
    }
    
    static func == (lhs: TestWordItem, rhs: TestWordItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.word == rhs.word &&
               lhs.userAnswer == rhs.userAnswer &&
               lhs.isAnswered == rhs.isAnswered &&
               lhs.isCorrect == rhs.isCorrect
    }
}

struct TestProgressData: Codable {
    let wordId: Int
    let swedish: String
    let english: String
    let userAnswer: String
    let isAnswered: Bool
    let isCorrect: Bool
}

struct TestView: View {
    @State private var testWords: [TestWordItem] = []
    @State private var selectedWordItem: TestWordItem?
    @State private var translationInput = ""
    @State private var showingScore = false
    @State private var showingHistory = false
    @State private var showingStopConfirmation = false
    @State private var testSavedToHistory = false
    @State private var isHistoricalTest = false // Track if this is a test loaded from history
    @State private var animatedItemId: UUID? = nil // Track which item should be animated
    @StateObject private var testDataManager = TestDataManager.shared
    @StateObject private var historyManager = TestHistoryManager.shared
    @StateObject private var wrongAnswersManager = WrongAnswersManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    private var allWordsAnswered: Bool {
        testWords.allSatisfy { $0.isAnswered }
    }
    
    private var score: (correct: Int, total: Int) {
        let correct = testWords.filter { $0.isCorrect }.count
        return (correct, testWords.count)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title and action buttons
            HStack {
                // Back button (only show when viewing historical test)
                if isHistoricalTest && !testWords.isEmpty {
                    Button(action: {
                        // If viewing historical test, clear it and show history view
                        testWords = []
                        isHistoricalTest = false
                        testSavedToHistory = false
                        showingHistory = true
                    }) {
                        Text("Back")
                    }
                } else {
                    // Invisible spacer when no button needed
                    Color.clear
                        .frame(width: 60, height: 44)
                }
                
                Spacer()
                
                HStack(spacing: 0) {
                    Text("Vocabulary")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    Text("Test")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                // Close button (only show when test is generated, all words are answered AND it's a new test, not historical)
                if !testWords.isEmpty && allWordsAnswered && !isHistoricalTest {
                    Button(action: {
                        // Save to history before closing if not already saved
                        if !testSavedToHistory {
                            saveTestToHistory()
                            testSavedToHistory = true
                        }
                        stopTest()
                        // Open history view after closing test
                        showingHistory = true
                    }) {
                        Text("Close")
                    }
                } else if isHistoricalTest && !testWords.isEmpty {
                    // Retake button for historical tests
                    Button(action: {
                        retakeTest()
                    }) {
                        Text("Retake")
                            .foregroundColor(.blue)
                    }
                } else if !testWords.isEmpty && !isHistoricalTest {
                    // X button for test in progress
                    Button(action: {
                        showingStopConfirmation = true
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(width: 44, height: 44)
                    }
                } else {
                    // Invisible spacer to balance the layout
                    Color.clear
                        .frame(width: 60, height: 44)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 20 : 20)
            
            // Generate button or word list
            if testWords.isEmpty {
                // Empty state with Generate button - centered vertically
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image("test")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                    
                    Text("Each test includes 10 randomly selected words. Type the English translation for each one. You can use hints if needed - good luck!")
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 15)
                    
                    Button(action: {
                        generateTest()
                    }) {
                        Text("Start new test")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    
                    Button(action: {
                        showingHistory = true
                    }) {
                        Text("My previous tests")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 12)
                    
                    Spacer()
                }
                .padding(.bottom, 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Word list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(testWords) { wordItem in
                            TestWordCard(
                                wordItem: wordItem,
                                isAnimating: animatedItemId == wordItem.id,
                                onStart: {
                                    translationInput = wordItem.userAnswer
                                    selectedWordItem = wordItem
                                }
                            )
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(item: $selectedWordItem) { selectedItem in
            TranslationInputModal(
                word: selectedItem.word,
                translation: $translationInput,
                onDone: { answer in
                    if let index = testWords.firstIndex(where: { $0.id == selectedItem.id }) {
                        let correctAnswer = testWords[index].word.english.lowercased().trimmingCharacters(in: .whitespaces)
                        let userAnswer = answer.lowercased().trimmingCharacters(in: .whitespaces)
                        let isCorrect = correctAnswer == userAnswer
                        
                        testWords[index].userAnswer = answer
                        testWords[index].isAnswered = true
                        testWords[index].isCorrect = isCorrect
                        
                        // Track wrong answers and correct answers for wrong answer words
                        let word = testWords[index].word
                        if !isCorrect {
                            // Add to wrong answers list
                            wrongAnswersManager.addWrongAnswer(swedish: word.swedish, english: word.english)
                        } else {
                            // If this word was in wrong answers, record the correct answer
                            wrongAnswersManager.recordCorrectAnswer(swedish: word.swedish, english: word.english)
                        }
                        
                        // Check if all words are answered (after updating current word)
                        let allAnswered = testWords.allSatisfy { $0.isAnswered }
                        
                        // Trigger animation for this item
                        animatedItemId = testWords[index].id
                        
                        // Clear animation after 0.5 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            animatedItemId = nil
                            
                            // If all words are answered and it's a new test, show completion popup
                            if allAnswered && !isHistoricalTest && !testSavedToHistory {
                                showingScore = true
                            }
                        }
                        
                        // Save progress after answering
                        if !isHistoricalTest {
                            saveTestProgress()
                        }
                    }
                    selectedWordItem = nil
                }
            )
        }
        .onAppear {
            // Load test progress when view appears (only if we don't already have words)
            if testWords.isEmpty {
                loadTestProgress()
            }
        }
        .onChange(of: testWords) { _, newValue in
            // Save test progress whenever it changes (but not for historical tests or when loading)
            if !newValue.isEmpty && !isHistoricalTest && !newValue.allSatisfy({ $0.userAnswer.isEmpty && !$0.isAnswered }) {
                saveTestProgress()
            }
        }
        .alert("All done!", isPresented: $showingScore) {
            Button("OK") {}
        } message: {
            Text("Your score is: \(score.correct)")
        }
        .alert("Are you sure?", isPresented: $showingStopConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Yes", role: .destructive) {
                stopTest()
            }
        } message: {
            Text("Test will be deleted.")
        }
        .sheet(isPresented: $showingHistory) {
            TestHistoryView(
                onSelectTest: { historyItem in
                    loadTestFromHistory(historyItem)
                    showingHistory = false
                }
            )
        }
    }
    
    private func generateTest() {
        clearTestProgress() // Clear any saved progress when generating new test
        testSavedToHistory = false // Reset flag when generating new test
        isHistoricalTest = false // Mark as new test, not historical
        
        var selectedWords: [TestWord] = []
        
        // Get 2 words from wrong answers list (if available)
        let wrongAnswerWords = wrongAnswersManager.getRandomWrongAnswerWords(count: 2)
        for wrongWord in wrongAnswerWords {
            if let word = testDataManager.getWordsByContent(swedish: wrongWord.swedish, english: wrongWord.english) {
                selectedWords.append(word)
            }
        }
        
        // Get remaining words from main list (excluding wrong answer words already selected)
        let remainingCount = 10 - selectedWords.count
        let excludedWords = selectedWords.map { (swedish: $0.swedish, english: $0.english) }
        let randomWords = testDataManager.getRandomWords(count: remainingCount, excludingWords: excludedWords)
        selectedWords.append(contentsOf: randomWords)
        
        // Ensure we have exactly 10 words
        guard selectedWords.count == 10 else {
            print("❌ Failed to generate test: Only got \(selectedWords.count) words instead of 10")
            return
        }
        
        // Shuffle all selected words to randomize order
        selectedWords.shuffle()
        
        testWords = selectedWords.map { TestWordItem(word: $0) }
        saveTestProgress() // Save the new test
        
        // Animate words one by one when they first appear
        animateWordsOnAppear()
    }
    
    private func animateWordsOnAppear() {
        // Animate each word with a delay
        for (index, wordItem) in testWords.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                animatedItemId = wordItem.id
                // Clear animation after 0.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if animatedItemId == wordItem.id {
                        animatedItemId = nil
                    }
                }
            }
        }
    }
    
    private func saveTestToHistory() {
        guard allWordsAnswered && !testWords.isEmpty else { return }
        
        let wordData = testWords.map { wordItem in
            TestWordItemData(
                wordId: wordItem.word.id,
                swedish: wordItem.word.swedish,
                english: wordItem.word.english,
                userAnswer: wordItem.userAnswer,
                isCorrect: wordItem.isCorrect
            )
        }
        
        let historyItem = TestHistoryItem(
            dateTaken: Date(),
            words: wordData,
            score: score.correct,
            total: score.total
        )
        
        historyManager.addHistoryItem(historyItem)
    }
    
    private func loadTestFromHistory(_ historyItem: TestHistoryItem) {
        clearTestProgress() // Clear any in-progress test when loading from history
        testSavedToHistory = true // Mark as already saved since it's from history
        isHistoricalTest = true // Mark as historical test
        // Load the words from history with their original answers and correctness
        // Look up the original word from TestDataManager to get the full word data including example
        testWords = historyItem.words.compactMap { wordData in
            // Try to find the original word with example data
            if let originalWord = testDataManager.getWordsByContent(swedish: wordData.swedish, english: wordData.english) {
                return TestWordItem(
                    word: originalWord,
                    userAnswer: wordData.userAnswer,
                    isAnswered: true, // Mark as answered to show historical results
                    isCorrect: wordData.isCorrect // Preserve original correctness
                )
            } else {
                // Fallback: create word without example if not found
                let word = TestWord(swedish: wordData.swedish, english: wordData.english)
                return TestWordItem(
                    word: word,
                    userAnswer: wordData.userAnswer,
                    isAnswered: true, // Mark as answered to show historical results
                    isCorrect: wordData.isCorrect // Preserve original correctness
                )
            }
        }
    }
    
    private func retakeTest() {
        // Reset all answers but keep the same words
        for index in testWords.indices {
            testWords[index].userAnswer = ""
            testWords[index].isAnswered = false
            testWords[index].isCorrect = false
        }
        // Mark as new test (not historical) so Done button will appear
        isHistoricalTest = false
        testSavedToHistory = false // Allow saving new attempt
        saveTestProgress() // Save the retake state
    }
    
    private func stopTest() {
        clearTestProgress()
        testWords = []
        isHistoricalTest = false
        testSavedToHistory = false
    }
    
    private func saveTestProgress() {
        guard !testWords.isEmpty else { return }
        
        let progressData = testWords.map { wordItem in
            TestProgressData(
                wordId: wordItem.word.id,
                swedish: wordItem.word.swedish,
                english: wordItem.word.english,
                userAnswer: wordItem.userAnswer,
                isAnswered: wordItem.isAnswered,
                isCorrect: wordItem.isCorrect
            )
        }
        
        do {
            let encoded = try JSONEncoder().encode(progressData)
            UserDefaults.standard.set(encoded, forKey: "testProgress")
        } catch {
            print("❌ Failed to save test progress: \(error)")
        }
    }
    
    private func loadTestProgress() {
        guard let data = UserDefaults.standard.data(forKey: "testProgress") else {
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([TestProgressData].self, from: data)
            
            // Check if the test is completed (all words answered)
            let allAnswered = decoded.allSatisfy { $0.isAnswered }
            
            if allAnswered {
                // Test is completed, clear it and show default view
                clearTestProgress()
                testWords = []
                return
            }
            
            // Test is incomplete, load it
            // Look up the original word from TestDataManager to get the full word data including example
            testWords = decoded.compactMap { progressData in
                // Try to find the original word with example data
                if let originalWord = testDataManager.getWordsByContent(swedish: progressData.swedish, english: progressData.english) {
                    return TestWordItem(
                        word: originalWord,
                        userAnswer: progressData.userAnswer,
                        isAnswered: progressData.isAnswered,
                        isCorrect: progressData.isCorrect
                    )
                } else {
                    // Fallback: create word without example if not found
                    let word = TestWord(swedish: progressData.swedish, english: progressData.english)
                    return TestWordItem(
                        word: word,
                        userAnswer: progressData.userAnswer,
                        isAnswered: progressData.isAnswered,
                        isCorrect: progressData.isCorrect
                    )
                }
            }
            // Restore the test state
            isHistoricalTest = false
            testSavedToHistory = false
        } catch {
            print("❌ Failed to load test progress: \(error)")
            // If decoding fails (e.g., old format with UUID), clear the old data
            clearTestProgress()
            testWords = []
        }
    }
    
    private func clearTestProgress() {
        UserDefaults.standard.removeObject(forKey: "testProgress")
    }
}

struct TestWordCard: View {
    let wordItem: TestWordItem
    let isAnimating: Bool
    let onStart: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var wrongAnswersManager = WrongAnswersManager.shared
    @StateObject private var audioManager = AudioManager()
    
    private var isWrongAnswerWord: Bool {
        let wrongWords = wrongAnswersManager.getWrongAnswerWords()
        return wrongWords.contains { wrongWord in
            wrongWord.swedish.lowercased() == wordItem.word.swedish.lowercased() &&
            wrongWord.english.lowercased() == wordItem.word.english.lowercased()
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if wordItem.isAnswered {
                // Swedish word (left half)
                Text(wordItem.word.swedish)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Vertical divider in the center
                Rectangle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 2)
                
                // English translation and icon (right half)
                HStack(spacing: 8) {
                    Text(wordItem.word.english)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: wordItem.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(wordItem.isCorrect ? .green : .red)
                        .font(.title3)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                // Audio icon on the left
                Button(action: {
                    audioManager.playAudio()
                }) {
                    Image("audio-headphone")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(audioManager.isAudioReady ? .blue : .gray)
                }
                .disabled(!audioManager.isAudioReady || audioManager.isPlaying)
                .padding(.trailing, 12)
                
                // Swedish word (centered when not answered)
                Text(wordItem.word.swedish)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                
                // Play button icon on the right
                Image("play-button")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 35, height: 35)
                    .foregroundColor(.blue)
                    .padding(.leading, 12)
            }
        }
        .padding(16)
        .background(
            wordItem.isAnswered 
                ? (wordItem.isCorrect ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                : (colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 20)
        .scaleEffect(isAnimating ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.5), value: isAnimating)
        .contentShape(Rectangle())
        .onTapGesture {
            if !wordItem.isAnswered {
                onStart()
            }
        }
        .onAppear {
            if !wordItem.isAnswered {
                audioManager.generateAudio(for: wordItem.word.swedish)
            }
        }
        .onChange(of: wordItem.word.swedish) { _, newValue in
            if !wordItem.isAnswered {
                audioManager.generateAudio(for: newValue)
            }
        }
        .onDisappear {
            audioManager.cleanupAudio()
        }
    }
}

struct TranslationInputModal: View {
    @Environment(\.dismiss) private var dismiss
    let word: TestWord
    @Binding var translation: String
    let onDone: (String) -> Void
    @FocusState private var isTextFieldFocused: Bool
    @State private var showingExample = false
    @State private var showingHint = false
    @State private var hintOptions: [String] = []
    @State private var showingFeedback = false
    @State private var isCorrect = false
    @State private var isAudioButtonPressed = false
    @State private var swedishWordFontSize: CGFloat = 48
    @StateObject private var testDataManager = TestDataManager.shared
    @StateObject private var audioManager = AudioManager()
    @Environment(\.colorScheme) var colorScheme
    
    // Helper function to make the specific word bold in the sentence
    private func makeBoldWordSentence(text: String, wordToBold: String) -> Text {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find all occurrences of the word (case-insensitive)
        var result = Text("")
        var currentIndex = trimmedText.startIndex
        
        while let range = trimmedText.range(of: wordToBold, options: [.caseInsensitive, .diacriticInsensitive], range: currentIndex..<trimmedText.endIndex) {
            // Add text before the word
            if currentIndex < range.lowerBound {
                let beforeText = String(trimmedText[currentIndex..<range.lowerBound])
                result = result + Text(beforeText)
            }
            
            // Add the bold word
            let boldWord = String(trimmedText[range])
            result = result + Text(boldWord)
                .fontWeight(.bold)
            
            // Move past this occurrence
            currentIndex = range.upperBound
        }
        
        // Add remaining text after the last occurrence
        if currentIndex < trimmedText.endIndex {
            let afterText = String(trimmedText[currentIndex..<trimmedText.endIndex])
            result = result + Text(afterText)
        }
        
        // If no word was found, return the original text
        if currentIndex == trimmedText.startIndex {
            return Text(trimmedText)
        }
        
        return result
    }
    
    private func generateHintOptions() {
        let correctAnswer = word.english
        
        // Get many random words to find 9 different ones (total 10 with correct answer)
        let allWords = testDataManager.getRandomWords(count: 100)
        
        // Get 9 random words that are NOT the correct answer (case-insensitive)
        var randomOptions: [String] = []
        var usedAnswers: Set<String> = [correctAnswer.lowercased()]
        
        for testWord in allWords {
            let english = testWord.english
            let englishLower = english.lowercased()
            
            // Skip if it's the correct answer or already used
            if !usedAnswers.contains(englishLower) {
                randomOptions.append(english)
                usedAnswers.insert(englishLower)
                if randomOptions.count >= 9 {
                    break
                }
            }
        }
        
        // If we couldn't find 9 unique options, just use what we have
        // Combine correct answer with random options and shuffle randomly
        var allOptions = [correctAnswer] + randomOptions
        allOptions.shuffle()
        
        hintOptions = allOptions
    }
    
    private var swedishWordDisplay: some View {
        VStack(spacing: 16) {
            Text("Translate this word:")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Text(word.swedish)
                    .font(.system(size: swedishWordFontSize, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                
                Button(action: {
                    // Trigger animation
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isAudioButtonPressed = true
                    }
                    audioManager.playAudio()
                    
                    // Reset animation after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isAudioButtonPressed = false
                        }
                    }
                }) {
                    Image("audio-headphone")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .foregroundColor(audioManager.isAudioReady ? .blue : .gray)
                        .scaleEffect(isAudioButtonPressed ? 0.9 : 1.0)
                }
                .disabled(audioManager.isPlaying || !audioManager.isAudioReady)
            }
        }
        .padding(.top, 80)
        .onAppear {
            calculateOptimalFontSize()
        }
        .onChange(of: word.swedish) {
            calculateOptimalFontSize()
        }
    }
    
    private func calculateOptimalFontSize() {
        // Reset to default first
        swedishWordFontSize = 48
        
        // Calculate after a brief delay to ensure layout is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let textWidth = measureTextWidth(text: word.swedish, fontSize: 48)
            // Estimate available width (screen width minus horizontal padding and button)
            // ContentView has padding of 30 on each side, so 60 total
            // Plus button width (48) and spacing (12) = 60
            let screenWidth = UIScreen.main.bounds.width
            let availableWidth = screenWidth - 60 - 60 // horizontal padding + button + spacing
            adjustFontSizeIfNeeded(textWidth: textWidth, availableWidth: availableWidth)
        }
    }
    
    private func measureTextWidth(text: String, fontSize: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        let attributes = [NSAttributedString.Key.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        return size.width
    }
    
    private func adjustFontSizeIfNeeded(textWidth: CGFloat, availableWidth: CGFloat) {
        // If text fits, use default size
        if textWidth <= availableWidth {
            if swedishWordFontSize != 48 {
                withAnimation(.easeInOut(duration: 0.2)) {
                    swedishWordFontSize = 48
                }
            }
            return
        }
        
        // Calculate the scale factor needed
        let scaleFactor = availableWidth / textWidth
        
        // Apply scale factor to font size, with a minimum of 32
        let newSize = max(32, 48 * scaleFactor)
        
        // Only update if significantly different to avoid constant updates
        if abs(swedishWordFontSize - newSize) > 1 {
            withAnimation(.easeInOut(duration: 0.2)) {
                swedishWordFontSize = newSize
            }
        }
    }
    
    private var translationInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("English translation:")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    TextField("Your answer...", text: $translation)
                        .font(.title3)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .focused($isTextFieldFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    if !translation.isEmpty {
                        Button(action: {
                            translation = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 20))
                                .padding(.trailing, 12)
                        }
                    }
                }
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(showingFeedback ? (isCorrect ? Color.green.opacity(0.2) : Color.red.opacity(0.2)) : (colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)))
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(showingFeedback ? (isCorrect ? Color.green : Color.red) : (isTextFieldFocused ? Color.blue : Color(.separator)), lineWidth: showingFeedback ? 2 : (isTextFieldFocused ? 2 : 1))
                )
                .animation(.easeInOut(duration: 0.2), value: showingFeedback)
                
                Button(action: {
                    // Check if answer is correct
                    let userAnswer = translation.trimmingCharacters(in: .whitespaces).lowercased()
                    let correctAnswer = word.english.trimmingCharacters(in: .whitespaces).lowercased()
                    isCorrect = userAnswer == correctAnswer
                    showingFeedback = true
                    
                    // Wait 1 second, then close modal
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        onDone(translation)
                        dismiss()
                    }
                }) {
                    Text("Validate")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .frame(height: 56)
                        .background(showingFeedback ? (isCorrect ? Color.green : Color.red) : (translation.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.blue))
                        .cornerRadius(12)
                }
                .disabled(translation.trimmingCharacters(in: .whitespaces).isEmpty)
                .animation(.easeInOut(duration: 0.2), value: showingFeedback)
            }
            .padding(.vertical, 20)
            
            // Display example sentence below the input field if available (only when showingExample is true)
            // Prefer example.sv over sentence (legacy)
            if showingExample {
                if let exampleSv = word.example?.sv, !exampleSv.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    makeBoldWordSentence(text: exampleSv.trimmingCharacters(in: .whitespacesAndNewlines), wordToBold: word.swedish)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .transition(.opacity)
                } else if let sentence = word.sentence, !sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // Fallback to legacy sentence field if example is not available
                    makeBoldWordSentence(text: sentence.trimmingCharacters(in: .whitespacesAndNewlines), wordToBold: word.swedish)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .transition(.opacity)
                }
            }
        }
        .padding(.horizontal, 30)
        .animation(.easeInOut(duration: 0.2), value: showingExample)
    }
    
    private var hintOptionsGrid: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left column (first 5 words)
            VStack(spacing: 8) {
                ForEach(Array(hintOptions.prefix(5).enumerated()), id: \.offset) { index, option in
                    Text(option)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .background(
                            Color.blue.opacity(0.1)
                        )
                        .cornerRadius(8)
                }
            }
            
            // Right column (last 5 words)
            VStack(spacing: 8) {
                ForEach(Array(hintOptions.suffix(5).enumerated()), id: \.offset) { index, option in
                    Text(option)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .background(
                            Color.blue.opacity(0.1)
                        )
                        .cornerRadius(8)
                }
            }
        }
    }
    
    @ViewBuilder
    private var hintOptionsSection: some View {
        if !hintOptions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                if showingHint {
                    Text("Here are some options:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                hintOptionsGrid
                    .blur(radius: showingHint ? 0 : 8)
                    .opacity(showingHint ? 1.0 : 0.6)
            }
            .padding(.horizontal, 30)
            .padding(.top, 10)
            .overlay(helpButtonOverlay)
            .animation(.easeInOut(duration: 0.2), value: showingHint)
            .animation(.easeInOut(duration: 0.2), value: showingExample)
        }
    }
    
    @ViewBuilder
    private var helpButtonOverlay: some View {
        // Show button if hint options are available and not yet shown
        if !showingHint {
            // Check if there's an example sentence available
            let hasExample = (word.example?.sv != nil && !word.example!.sv.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ||
                            (word.sentence != nil && !word.sentence!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        if !showingExample && hasExample {
                            // First click: show example sentence
                            withAnimation {
                                showingExample = true
                            }
                        } else {
                            // Second click (or if no example): show hint options
                            withAnimation {
                                showingHint = true
                            }
                        }
                    }) {
                        Text((showingExample && hasExample) ? "More help" : "I Need help...")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                    Spacer()
                }
                Spacer()
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    swedishWordDisplay
                    translationInputSection
                    hintOptionsSection
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isTextFieldFocused = false
                    }
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
            // Generate hint options on appear so they're ready to display
            if hintOptions.isEmpty {
                generateHintOptions()
            }
            // Generate audio for the Swedish word
            audioManager.generateAudio(for: word.swedish)
            // Debug: Print example if available
            if let example = word.example {
                print("📝 Example for '\(word.swedish)': sv='\(example.sv)', en='\(example.en)'")
            } else if let sentence = word.sentence {
                print("📝 Legacy sentence for '\(word.swedish)': '\(sentence)'")
            } else {
                print("⚠️ No example or sentence for '\(word.swedish)'")
            }
        }
        .onDisappear {
            audioManager.cleanupAudio()
        }
    }
}

struct TestHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var historyManager = TestHistoryManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var animatedItemId: UUID? = nil
    let onSelectTest: (TestHistoryItem) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if historyManager.historyItems.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No test history")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Complete a test to see it in your history")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .padding(.top, 50)
                    .padding(.bottom, 60)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(historyManager.historyItems) { historyItem in
                                Button(action: {
                                    onSelectTest(historyItem)
                                }) {
                                    TestHistoryCard(
                                        historyItem: historyItem,
                                        isAnimating: animatedItemId == historyItem.id
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 20)
                    }
                    .onAppear {
                        // Animate the first item (newly added) when view appears
                        if let firstItem = historyManager.historyItems.first {
                            animatedItemId = firstItem.id
                            // Clear animation after 0.5 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                animatedItemId = nil
                            }
                        }
                    }
                    .onChange(of: historyManager.historyItems) { _, newValue in
                        // Animate newly added item when history changes
                        if let firstItem = newValue.first, animatedItemId == nil {
                            animatedItemId = firstItem.id
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                animatedItemId = nil
                            }
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Test History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TestHistoryCard: View {
    let historyItem: TestHistoryItem
    let isAnimating: Bool
    @Environment(\.colorScheme) var colorScheme
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy 'at' HH:mm"
        return formatter
    }
    
    private func colorForSquare(_ number: Int) -> Color {
        // Color gradient: 1 = red, 5 = orange, 10 = green
        if number <= 5 {
            // Interpolate from red (1) to orange (5)
            // Red RGB: (1, 0, 0), Orange RGB: (1, 0.65, 0)
            let ratio = Double(number - 1) / 4.0 // 0.0 for 1, 1.0 for 5
            let red = 1.0 // Always 1.0
            let green = ratio * 0.65 // 0.0 -> 0.65
            let blue = 0.0
            return Color(red: red, green: green, blue: blue)
        } else {
            // Interpolate from orange (5) to green (10)
            // Orange RGB: (1, 0.65, 0), Green RGB: (0, 1, 0)
            let ratio = Double(number - 5) / 5.0 // 0.0 for 5, 1.0 for 10
            let red = 1.0 - ratio // 1.0 -> 0.0
            let green = 0.65 + (ratio * 0.35) // 0.65 -> 1.0
            let blue = 0.0
            return Color(red: red, green: green, blue: blue)
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(dateFormatter.string(from: historyItem.dateTaken))
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
            
            // Score squares (1-10) - evenly spread with minimal spacing
            HStack(spacing: -4) {
                ForEach(1...10, id: \.self) { number in
                    let isScoreSquare = historyItem.score > 0 && number == historyItem.score
                    let size: CGFloat = isScoreSquare ? 32 : 22
                    let borderWidth: CGFloat = isScoreSquare ? 2.5 : 0
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(colorForSquare(number))
                            .frame(width: size, height: size)
                        
                        if borderWidth > 0 {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: borderWidth)
                                .frame(width: size, height: size)
                        }
                        
                        Text("\(number)")
                            .font(.system(size: isScoreSquare ? 14 : 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    if number < 10 {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 12)
                    }
                }
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 20)
        .scaleEffect(isAnimating ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.5), value: isAnimating)
    }
}

#Preview {
    TestView()
}
