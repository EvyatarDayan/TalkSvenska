import Foundation

struct WrongAnswerData: Codable {
    let swedish: String
    let english: String
    let count: Int // Count of correct answers (0-2)
}

class WrongAnswersManager: ObservableObject {
    static let shared = WrongAnswersManager()
    
    // Dictionary: swedish+english key -> count of correct answers (0-2)
    // If count reaches 2, the word is removed
    @Published private var wrongAnswers: [String: Int] = [:]
    
    private init() {
        loadWrongAnswers()
    }
    
    private func wordKey(swedish: String, english: String) -> String {
        return "\(swedish.lowercased())|\(english.lowercased())"
    }
    
    func addWrongAnswer(swedish: String, english: String) {
        let key = wordKey(swedish: swedish, english: english)
        // Only add if not already in the list (or reset if it was removed)
        if wrongAnswers[key] == nil {
            wrongAnswers[key] = 0
            saveWrongAnswers()
        }
    }
    
    func recordCorrectAnswer(swedish: String, english: String) {
        let key = wordKey(swedish: swedish, english: english)
        if let currentCount = wrongAnswers[key] {
            let newCount = currentCount + 1
            if newCount >= 2 {
                // Remove after 2 correct answers
                wrongAnswers.removeValue(forKey: key)
            } else {
                wrongAnswers[key] = newCount
            }
            saveWrongAnswers()
        }
    }
    
    func getWrongAnswerWords() -> [(swedish: String, english: String)] {
        return wrongAnswers.keys.compactMap { key in
            let parts = key.split(separator: "|")
            guard parts.count == 2 else { return nil }
            return (swedish: String(parts[0]), english: String(parts[1]))
        }
    }
    
    func getRandomWrongAnswerWords(count: Int) -> [(swedish: String, english: String)] {
        let wrongWords = getWrongAnswerWords()
        guard !wrongWords.isEmpty else { return [] }
        
        let shuffled = wrongWords.shuffled()
        return Array(shuffled.prefix(min(count, shuffled.count)))
    }
    
    private func saveWrongAnswers() {
        // Convert to array of WrongAnswerData for encoding
        let data = wrongAnswers.compactMap { key, count -> WrongAnswerData? in
            let parts = key.split(separator: "|")
            guard parts.count == 2 else { return nil }
            return WrongAnswerData(swedish: String(parts[0]), english: String(parts[1]), count: count)
        }
        
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: "wrongAnswers")
        }
    }
    
    private func loadWrongAnswers() {
        guard let data = UserDefaults.standard.data(forKey: "wrongAnswers") else {
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([WrongAnswerData].self, from: data)
            wrongAnswers = Dictionary(uniqueKeysWithValues: decoded.map { data in
                let key = wordKey(swedish: data.swedish, english: data.english)
                return (key, data.count)
            })
        } catch {
            print("❌ Failed to load wrong answers: \(error)")
            wrongAnswers = [:]
        }
    }
}

