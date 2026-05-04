//
//  SentenceModalView.swift
//  TalkSvenska
//
//  Created by EVYATAR DAYAN on 14/08/2025.
//

import SwiftUI
import Pow
import AVFoundation
import AudioToolbox
import Foundation

struct SentenceModalView: View {
    let initialSentence: Sentence
    let topic: String
    let onDismiss: () -> Void
    let onRefresh: () -> Void
    @State private var currentSentence: Sentence
    @State private var showTranslation = false
    @State private var isRefreshing = false
    @State private var isFavorite = false
    @State private var sentenceHistory: [Sentence] = []
    @State private var currentHistoryIndex: Int = -1
    @StateObject private var audioManager = AudioManager()
    
    init(sentence: Sentence, topic: String, onDismiss: @escaping () -> Void, onRefresh: @escaping () -> Void) {
        self.initialSentence = sentence
        self.topic = topic
        self.onDismiss = onDismiss
        self.onRefresh = onRefresh
        self._currentSentence = State(initialValue: sentence)
        self._isFavorite = State(initialValue: FavoriteManager.shared.isFavorite(sentence))
        self._sentenceHistory = State(initialValue: [sentence])
        self._currentHistoryIndex = State(initialValue: 0)
    }
    
    var body: some View {
        NavigationView {
            ZStack {

                
                // Main layout - Swedish and English sections at top, buttons below
                VStack(spacing: 0) {
                    // Swedish section at the top
                    VStack(spacing: 20) {
                        Text("Swedish")
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
                            print("🔄 Previous button tapped")
                            if currentHistoryIndex > 0 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isRefreshing = true
                                    showTranslation = false
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    currentHistoryIndex -= 1
                                    let previousSentence = sentenceHistory[currentHistoryIndex]
                                    currentSentence = previousSentence
                                    isFavorite = FavoriteManager.shared.isFavorite(previousSentence)
                                    print("🔄 Going to previous sentence: \(previousSentence.swedish)")
                                    print("🔄 History index: \(currentHistoryIndex)")
                                    
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isRefreshing = false
                                    }
                                }
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.blue)
                                .frame(width: 70, height: 70)
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
                                .frame(width: 70, height: 70)
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
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isRefreshing = true
                                showTranslation = false
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                if currentHistoryIndex < sentenceHistory.count - 1 {
                                    currentHistoryIndex += 1
                                    let nextSentence = sentenceHistory[currentHistoryIndex]
                                    currentSentence = nextSentence
                                    isFavorite = FavoriteManager.shared.isFavorite(nextSentence)
                                    print("🔄 Going to next sentence: \(nextSentence.swedish)")
                                    print("🔄 History index: \(currentHistoryIndex)")
                                } else {
                                    let newSentence = getRandomSentenceForTopic(topic)
                                    sentenceHistory.append(newSentence)
                                    currentHistoryIndex = sentenceHistory.count - 1
                                    currentSentence = newSentence
                                    print("🔄 New sentence: \(newSentence.swedish)")
                                    print("🔄 History count: \(sentenceHistory.count), Index: \(currentHistoryIndex)")
                                }
                                
                                let newFavoriteState = FavoriteManager.shared.isFavorite(currentSentence)
                                isFavorite = newFavoriteState
                                
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isRefreshing = false
                                }
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.blue)
                                .frame(width: 70, height: 70)
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
                        .padding(.top, UIDevice.current.userInterfaceIdiom == .pad ? 150 : 200)     // English translation position
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .leading)),
                            removal: .opacity
                        ))
                        
                        Spacer()
                    }
                    .zIndex(1)
                }
            }
            .navigationTitle(topic)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        print("🔄 Favorite button tapped for: \(currentSentence.swedish)")
                        print("🔄 Current isFavorite state: \(isFavorite)")
                        
                        // Toggle the state first
                        isFavorite.toggle()
                        
                        // Then update the favorites list
                        if isFavorite {
                            // Now favorited, so add to favorites
                            FavoriteManager.shared.addFavorite(currentSentence)
                        } else {
                            // Now unfavorited, so remove from favorites
                            FavoriteManager.shared.removeFavorite(currentSentence)
                        }
                        
                        print("🔄 New isFavorite state: \(isFavorite)")
                    }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(isFavorite ? .red : .primary)
                            .frame(width: 30, height: 30)
                    }
                    .scaleEffect(isRefreshing ? 0.9 : 1.0)
                    .opacity(isRefreshing ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isRefreshing)
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
        }
        .onAppear {
            print("🔍 Modal opened with topic: '\(topic)'")
            print("🔍 Sentence: '\(currentSentence.swedish)'")
            audioManager.generateAudio(for: currentSentence.swedish)
        }
        .onChange(of: currentSentence) {
            audioManager.generateAudio(for: currentSentence.swedish)
        }
        .onDisappear {
            audioManager.cleanupAudio()
        }
    }
    
    // MARK: - Helper Functions
    
    private func getRandomSentenceForTopic(_ topic: String) -> Sentence {
        switch topic.lowercased() {
        case "school":
            return SchoolData.getRandomSentence()
        case "transportation":
            return TransportationData.getRandomSentence()
        case "restaurant":
            return RestaurantData.getRandomSentence()
        case "travel":
            return TravelData.getRandomSentence()
        case "shopping":
            return ShoppingData.getRandomSentence()
        case "weather":
            return WeatherData.getRandomSentence()
        case "family":
            return FamilyData.getRandomSentence()
        case "work":
            return WorkData.getRandomSentence()
        case "hobbies":
            return HobbiesData.getRandomSentence()
        case "health":
            return HealthData.getRandomSentence()
        case "directions":
            return DirectionsData.getRandomSentence()
        case "numbers":
            return NumbersData.getRandomSentence()
        default:
            return SchoolData.getRandomSentence()
        }
    }
    

}

// MARK: - FavoriteManager
class FavoriteManager: ObservableObject {
    static let shared = FavoriteManager()
    
    @Published var favorites: [Sentence] = []
    
    private init() {
        loadFavorites()
    }
    
    func addFavorite(_ sentence: Sentence) {
        // Check if sentence is already in favorites
        if !favorites.contains(where: { $0.id == sentence.id }) {
            favorites.append(sentence)
            print("✅ Added favorite: \(sentence.swedish)")
            print("📋 Total favorites now: \(favorites.count)")
            saveFavorites()
        } else {
            print("⚠️ Sentence already in favorites: \(sentence.swedish)")
        }
    }
    
    func removeFavorite(_ sentence: Sentence) {
        let initialCount = favorites.count
        favorites.removeAll { $0.id == sentence.id }
        let finalCount = favorites.count
        
        if initialCount != finalCount {
            print("✅ Removed favorite: \(sentence.swedish)")
            print("📋 Total favorites now: \(favorites.count)")
            saveFavorites()
        } else {
            print("⚠️ Sentence not found in favorites: \(sentence.swedish)")
        }
    }
    
    func isFavorite(_ sentence: Sentence) -> Bool {
        let isFav = favorites.contains { $0.id == sentence.id }
        print("🔍 Checking if favorite: \(sentence.swedish) → \(isFav)")
        return isFav
    }
    
    func getAllFavorites() -> [Sentence] {
        print("📋 Total favorites: \(favorites.count)")
        return favorites
    }
    
    private func saveFavorites() {
        do {
            let encoded = try JSONEncoder().encode(favorites)
            UserDefaults.standard.set(encoded, forKey: "favorites")
            print("💾 Saved \(favorites.count) favorites to storage")
        } catch {
            print("❌ Failed to save favorites: \(error)")
        }
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: "favorites") {
            do {
                let decoded = try JSONDecoder().decode([Sentence].self, from: data)
                favorites = decoded
                print("📥 Loaded \(favorites.count) favorites from storage")
            } catch {
                print("❌ Failed to load favorites: \(error)")
                favorites = []
            }
        } else {
            print("📥 No saved favorites found, starting with empty list")
            favorites = []
        }
    }
    
    func clearAllFavorites() {
        favorites = []
        UserDefaults.standard.removeObject(forKey: "favorites")
        print("🗑️ Cleared all favorites")
    }
    
    /// Replaces favorites order and persists (used after validating an import file).
    func replaceFavorites(with sentences: [Sentence]) {
        favorites = sentences
        saveFavorites()
    }
    
    // Export favorites as JSON string for backup
    func exportFavorites() -> String? {
        do {
            let encoded = try JSONEncoder().encode(favorites)
            return String(data: encoded, encoding: .utf8)
        } catch {
            print("❌ Failed to export favorites: \(error)")
            return nil
        }
    }
    
    /// Import from UTF-8 JSON (same format as export). Preserves order and sentence fields.
    func importFavorites(from data: Data) -> Bool {
        do {
            let decoded = try JSONDecoder().decode([Sentence].self, from: data)
            replaceFavorites(with: decoded)
            print("✅ Successfully imported \(decoded.count) favorites")
            return true
        } catch {
            print("❌ Failed to import favorites: \(error)")
            return false
        }
    }
    
    func importFavorites(from jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else {
            print("❌ Failed to convert JSON string to data")
            return false
        }
        return importFavorites(from: data)
    }
}

// MARK: - AudioManager
class AudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var isAudioReady = false
    private var audioPlayer: AVAudioPlayer?
    private var audioURL: URL?
    private var currentText: String = ""
    
    func generateAudio(for text: String) {
        // Reset state
        isAudioReady = false
        isPlaying = false
        currentText = text
        
        print("Generating audio for: \(text)")
        
        // Use Apple's built-in TTS with better voice selection
        generateTTSAudio(for: text)
    }
    
    func playAudio() {
        guard !isPlaying, isAudioReady else { 
            print("Cannot play audio - isPlaying: \(isPlaying), isReady: \(isAudioReady)")
            return 
        }
        
        print("Playing TTS audio...")
        isPlaying = true
        
        // Try web-based TTS first, then fallback to system sound
        playWebTTS()
    }
    
    func cleanupAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        isAudioReady = false
        
        // Delete the audio file
        if let audioURL = audioURL {
            try? FileManager.default.removeItem(at: audioURL)
        }
        audioURL = nil
    }
    

    
    private func generateTTSAudio(for text: String) {
        print("Generating TTS audio for: \(text)")
        
        // Set up audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            print("Audio session configured successfully")
        } catch {
            print("Failed to configure audio session: \(error)")
            self.isAudioReady = false
            return
        }
        
        // Use direct speech synthesis instead of file generation
        // This avoids the problematic write method and pipe errors
        self.isAudioReady = true
        print("TTS ready for direct playback")
    }
    

    
    private func playWebTTS() {
        // Use Google Translate TTS API (free and reliable)
        let encodedText = currentText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://translate.google.com/translate_tts?ie=UTF-8&q=\(encodedText)&tl=sv&client=tw-ob"
        
        guard let url = URL(string: urlString) else {
            print("Failed to create TTS URL")
            playFallbackSound()
            return
        }
        
        print("Fetching TTS from: \(urlString)")
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("TTS network error: \(error)")
                    self.playFallbackSound()
                    return
                }
                
                guard let data = data, !data.isEmpty else {
                    print("No TTS data received")
                    self.playFallbackSound()
                    return
                }
                
                // Save the audio data to a temporary file
                let filename = "web_tts_\(UUID().uuidString).mp3"
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let audioURL = documentsPath.appendingPathComponent(filename)
                
                do {
                    try data.write(to: audioURL)
                    print("Web TTS audio saved successfully")
                    
                    // Create audio player
                    self.audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                    self.audioPlayer?.delegate = self
                    self.audioPlayer?.prepareToPlay()
                    self.audioPlayer?.play()
                    
                } catch {
                    print("Error playing web TTS: \(error)")
                    self.playFallbackSound()
                }
            }
        }
        
        task.resume()
    }
    
    private func playFallbackSound() {
        print("Playing fallback system sound")
        AudioServicesPlaySystemSound(1005)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isPlaying = false
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
    

}

// MARK: - Flip Animation Modifier
struct FlipModifier: ViewModifier {
    let angle: Double
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(angle),
                axis: (x: 0.0, y: 1.0, z: 0.0)
            )
    }
}

#Preview {
    SentenceModalView(
        sentence: Sentence(swedish: "Jag går till skolan.", english: "I go to school."),
        topic: "School",
        onDismiss: {},
        onRefresh: {}
    )
}
