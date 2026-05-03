import Foundation

struct TestHistoryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let dateTaken: Date
    let words: [TestWordItemData]
    let score: Int
    let total: Int
    
    init(id: UUID = UUID(), dateTaken: Date, words: [TestWordItemData], score: Int, total: Int) {
        self.id = id
        self.dateTaken = dateTaken
        self.words = words
        self.score = score
        self.total = total
    }
    
    static func == (lhs: TestHistoryItem, rhs: TestHistoryItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.dateTaken == rhs.dateTaken &&
               lhs.words == rhs.words &&
               lhs.score == rhs.score &&
               lhs.total == rhs.total
    }
}

struct TestWordItemData: Codable, Equatable {
    let wordId: Int
    let swedish: String
    let english: String
    let userAnswer: String
    let isCorrect: Bool
    
    // Regular initializer
    init(wordId: Int, swedish: String, english: String, userAnswer: String, isCorrect: Bool) {
        self.wordId = wordId
        self.swedish = swedish
        self.english = english
        self.userAnswer = userAnswer
        self.isCorrect = isCorrect
    }
    
    // Custom decoder to handle migration from UUID (string) to Int
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        swedish = try container.decode(String.self, forKey: .swedish)
        english = try container.decode(String.self, forKey: .english)
        userAnswer = try container.decode(String.self, forKey: .userAnswer)
        isCorrect = try container.decode(Bool.self, forKey: .isCorrect)
        
        // Handle migration: try Int first, if fails try String (old UUID format)
        if let intId = try? container.decode(Int.self, forKey: .wordId) {
            wordId = intId
        } else if let stringId = try? container.decode(String.self, forKey: .wordId) {
            // Old UUID format - convert to Int hash
            wordId = abs(stringId.hashValue)
        } else {
            // Fallback: generate from content
            let content = "\(swedish.lowercased())|\(english.lowercased())"
            wordId = abs(content.hashValue)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case wordId, swedish, english, userAnswer, isCorrect
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(wordId, forKey: .wordId)
        try container.encode(swedish, forKey: .swedish)
        try container.encode(english, forKey: .english)
        try container.encode(userAnswer, forKey: .userAnswer)
        try container.encode(isCorrect, forKey: .isCorrect)
    }
}

class TestHistoryManager: ObservableObject {
    static let shared = TestHistoryManager()
    
    @Published var historyItems: [TestHistoryItem] = []
    
    private init() {
        loadHistory()
    }
    
    func addHistoryItem(_ item: TestHistoryItem) {
        historyItems.insert(item, at: 0) // Add to beginning
        saveHistory()
    }
    
    func removeHistoryItem(_ item: TestHistoryItem) {
        historyItems.removeAll { $0.id == item.id }
        saveHistory()
    }
    
    func clearAllHistory() {
        historyItems.removeAll()
        saveHistory()
    }
    
    private func saveHistory() {
        do {
            let encoded = try JSONEncoder().encode(historyItems)
            UserDefaults.standard.set(encoded, forKey: "testHistory")
        } catch {
            print("❌ Failed to save test history: \(error)")
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "testHistory") {
            do {
                let decoded = try JSONDecoder().decode([TestHistoryItem].self, from: data)
                historyItems = decoded
            } catch {
                print("❌ Failed to load test history: \(error)")
                // If loading fails (e.g., old format), clear the old history
                // This allows the app to continue working with new format
                UserDefaults.standard.removeObject(forKey: "testHistory")
                historyItems = []
            }
        }
    }
}

