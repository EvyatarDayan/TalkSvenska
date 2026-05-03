import Foundation

struct WordExample: Codable {
    let sv: String
    let en: String
}

struct TestWordJSON: Codable {
    let id: Int? // Optional id field from JSON
    let swedish: String
    let english: String? // Make optional to handle null values
    let sentence: String? // Optional sentence field (legacy)
    let example: WordExample? // Optional example field with sv and en
}

struct TestWord: Identifiable, Equatable {
    let id: Int
    let swedish: String
    let english: String
    let sentence: String? // Optional sentence field (legacy)
    let example: WordExample? // Optional example field with sv and en
    
    init(id: Int? = nil, swedish: String, english: String, sentence: String? = nil, example: WordExample? = nil) {
        // Use provided id, or generate one from content hash if not provided
        if let providedId = id {
            self.id = providedId
        } else {
            // Generate a stable id from content hash
            let content = "\(swedish.lowercased())|\(english.lowercased())"
            self.id = abs(content.hashValue)
        }
        self.swedish = swedish
        self.english = english
        self.sentence = sentence
        self.example = example
    }
    
    static func == (lhs: TestWord, rhs: TestWord) -> Bool {
        return lhs.id == rhs.id &&
               lhs.swedish == rhs.swedish &&
               lhs.english == rhs.english &&
               lhs.sentence == rhs.sentence &&
               lhs.example?.sv == rhs.example?.sv &&
               lhs.example?.en == rhs.example?.en
    }
}

class TestDataManager: ObservableObject {
    static let shared = TestDataManager()
    
    private var allWords: [TestWord] = []
    
    private init() {
        loadWords()
    }
    
    func loadWords() {
        guard let url = Bundle.main.url(forResource: "testWords", withExtension: "json") else {
            print("❌ Could not find testWords.json file")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let jsonWords = try decoder.decode([TestWordJSON].self, from: data)
            // Filter out words with null english values and map to TestWord
            allWords = jsonWords.compactMap { jsonWord in
                // Skip words with null or empty english
                guard let english = jsonWord.english, !english.isEmpty else {
                    print("⚠️ Skipping word with null/empty english: \(jsonWord.swedish)")
                    return nil
                }
                return TestWord(
                    id: jsonWord.id,
                    swedish: jsonWord.swedish,
                    english: english,
                    sentence: jsonWord.sentence,
                    example: jsonWord.example
                )
            }
            print("✅ Loaded \(allWords.count) test words")
        } catch {
            print("❌ Error loading test words: \(error)")
        }
    }
    
    func getRandomWords(count: Int, excludingWords: [(swedish: String, english: String)] = []) -> [TestWord] {
        guard !allWords.isEmpty else { return [] }
        
        // Create a set of excluded word keys for fast lookup
        let excludedKeys = Set(excludingWords.map { "\($0.swedish.lowercased())|\($0.english.lowercased())" })
        
        // Filter out excluded words
        let availableWords = allWords.filter { word in
            let key = "\(word.swedish.lowercased())|\(word.english.lowercased())"
            return !excludedKeys.contains(key)
        }
        
        let requestedCount = min(count, availableWords.count)
        
        // Create a shuffled copy of available words to ensure true randomness
        let shuffledWords = availableWords.shuffled()
        
        // Take the first 'count' words from the shuffled array
        // This ensures we get different random words each time
        return Array(shuffledWords.prefix(requestedCount))
    }
    
    func getWordsByContent(swedish: String, english: String) -> TestWord? {
        return allWords.first { word in
            word.swedish.lowercased() == swedish.lowercased() &&
            word.english.lowercased() == english.lowercased()
        }
    }
}

