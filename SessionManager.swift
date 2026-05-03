import Foundation

class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @Published var hasShownManualBlurHint = false
    @Published var hasShownFavoritesBlurHint = false
    @Published var hasShownManualDictationHint = false
    
    private init() {
        // Reset when app launches
        resetSession()
    }
    
    func resetSession() {
        hasShownManualBlurHint = false
        hasShownFavoritesBlurHint = false
        hasShownManualDictationHint = false
    }
}

