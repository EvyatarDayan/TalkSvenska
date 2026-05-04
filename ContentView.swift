//
//  ContentView.swift
//  TalkSvenska
//
//  Created by EVYATAR DAYAN on 14/08/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 3
    @State private var currentSentence: Sentence?
    @State private var currentTopic: String = "Random"
    @State private var showingScheduler = false
    @State private var openedFromNotification = false
    @StateObject private var favoriteManager = FavoriteManager.shared
    @StateObject private var sessionManager = SessionManager.shared
    @Binding var showRandomSentence: Bool
    @State private var favoritesSearchText = ""
    @State private var showFavoritesBlurHint = false
    @State private var selectedFavoritesFilter: FilterOption = .all
    @FocusState private var isFavoritesSearchFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    
    // Store the last used topic in UserDefaults
    @AppStorage("lastUsedTopic") private var lastUsedTopic: String = "Random"
    // Store hint dismissal state persistently
    @AppStorage("hasShownFavoritesBlurHint") private var hasShownFavoritesBlurHint = false
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case recent = "Recent"
    }
    
    // Menu height constant - adjust this to change menu height
    private let menuHeight: CGFloat = 40
    // Menu button spacing - adjust this to change spacing between buttons (negative values bring them closer)
    private let menuButtonSpacing: CGFloat = -40
    
    let topics = [
        "Transportation",
        "Restaurant", 
        "School",
        "Travel",
        "Shopping",
        "Weather",
        "Family",
        "Work",
        "Hobbies",
        "Health",
        "Directions",
        "Numbers"
    ]
    
    // Filtered favorites based on filter and search text
    var filteredFavorites: [Sentence] {
        var sentences: [Sentence] = favoriteManager.favorites
        
        // Apply filter
        switch selectedFavoritesFilter {
        case .all:
            // Keep all favorites
            break
        case .recent:
            // Last 30 items added (most recent first)
            // Since new favorites are appended to the array, the last items are the most recent
            // Take the last 30 items and reverse so most recent is first
            let totalCount = favoriteManager.favorites.count
            let startIndex = max(0, totalCount - 30)
            sentences = Array(favoriteManager.favorites[startIndex..<totalCount])
            sentences = sentences.reversed() // Most recent first
        }
        
        // Apply search text filter
        if !favoritesSearchText.isEmpty {
            let lowercasedSearch = favoritesSearchText.lowercased()
            sentences = sentences.filter { sentence in
                sentence.swedish.lowercased().contains(lowercasedSearch) ||
                sentence.english.lowercased().contains(lowercasedSearch)
            }
        }
        
        return sentences
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Light gray background for entire view including safe area
                Color(.systemGroupedBackground)
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Main content area
                    mainContentArea
                        .frame(width: geometry.size.width, height: geometry.size.height - menuHeight)
                        .clipped()
                    
                    // Footer menu with new design
                    footerMenu(geometry: geometry)
                }
            }
        }
        .sheet(item: $currentSentence) { sentence in
            SentenceModalView(
                sentence: sentence, 
                topic: currentTopic,
                onDismiss: {
                    currentSentence = nil
                },
                onRefresh: {
                    // Generate new random sentence from the same topic
                    let newSentence = getRandomSentenceForTopic(currentTopic)
                    currentSentence = newSentence
                }
            )
        }
        .overlay(
            Group {
                if currentSentence != nil && UIDevice.current.userInterfaceIdiom == .pad {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                }
            }
        )
        .onAppear {
            // Initialize currentTopic from last used topic
            currentTopic = lastUsedTopic
            print("📱 App opened - Current topic: \(currentTopic)")
            
            // Show favorites hint on first item if not shown before
            if selectedTab == 1 && !hasShownFavoritesBlurHint && !favoriteManager.favorites.isEmpty && favoritesSearchText.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !hasShownFavoritesBlurHint {
                        showFavoritesBlurHint = true
                    }
                }
            }
        }
        .onChange(of: favoritesSearchText) {
            // Hide hint when searching
            if !favoritesSearchText.isEmpty {
                showFavoritesBlurHint = false
            } else if !hasShownFavoritesBlurHint && !favoriteManager.favorites.isEmpty {
                // Show hint again if search is cleared and hint hasn't been shown
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !hasShownFavoritesBlurHint {
                        showFavoritesBlurHint = true
                    }
                }
            }
        }
        .onChange(of: showRandomSentence) { oldValue, newValue in
            print("📱 showRandomSentence changed to: \(newValue)")
            if newValue {
                print("📱 showRandomSentence changed to true - opening from notification")
                openedFromNotification = true
                selectedTab = 2 // Switch to home tab
                showRandomSentence = false
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // Auto-trigger random selection when switching to home tab from notification
            if newValue == 2 && openedFromNotification {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("📱 Auto-triggering random selection from notification")
                    selectRandomSentenceFromAllTopics()
                    openedFromNotification = false // Reset the flag
                }
            }
            
            // Show favorites hint when switching to favorites tab
            if newValue == 1 && !hasShownFavoritesBlurHint && !favoriteManager.favorites.isEmpty && favoritesSearchText.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !hasShownFavoritesBlurHint {
                        showFavoritesBlurHint = true
                    }
                }
            } else if newValue != 1 {
                showFavoritesBlurHint = false
            }
        }
        .toolbar {
            if selectedTab == 1 { // Only show keyboard toolbar on Favorites tab
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isFavoritesSearchFocused = false
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var mainContentArea: some View {
        if selectedTab == 0 {
            TestView()
        } else if selectedTab == 1 {
            favoritesView
        } else if selectedTab == 2 {
            homeView
        } else if selectedTab == 3 {
            ManualView()
        } else {
            SettingsView()
        }
    }
    
    @ViewBuilder
    private var favoritesView: some View {
        VStack(spacing: 0) {
            favoritesTitle
            favoritesSearchBar
            favoritesFilter
                    
                    if favoriteManager.favorites.isEmpty {
                favoritesEmptyState
            } else {
                favoritesList
            }
        }
    }
    
    private var favoritesTitle: some View {
        HStack(spacing: 0) {
            Text("Favo")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
            Text("rites")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.green)
        }
        .padding(.top, 20)
        .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 20 : 22)
    }
    
    private var favoritesSearchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .padding(.leading, 12)
                
                TextField("Search...", text: $favoritesSearchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.vertical, 10)
                    .focused($isFavoritesSearchFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                if !favoritesSearchText.isEmpty {
                    Button(action: {
                        favoritesSearchText = ""
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
    }
    
    private var favoritesFilter: some View {
        HStack {
            Picker("Filter", selection: $selectedFavoritesFilter) {
                ForEach(FilterOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(maxWidth: .infinity)
            
            // Item count
            Text("\(filteredFavorites.count) Items")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
        .padding(.top, 12)
    }
    
    private var favoritesEmptyState: some View {
                        VStack(spacing: 20) {
                            Image(systemName: "heart")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No favorites yet")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            
                            Text("Tap the heart icon on any sentence to add it to your favorites")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
            
            Spacer()
                        }
                        .padding(.top, 100)
    }
    
    @ViewBuilder
    private var favoritesList: some View {
        GeometryReader { geometry in
            if filteredFavorites.isEmpty {
                // No results found
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
                    } else {
                            List {
                    ForEach(Array(filteredFavorites.enumerated()), id: \.element.id) { index, sentence in
                                    FavoriteSentenceCard(
                                        sentence: sentence,
                            topic: getTopicForSentence(sentence),
                            isFirstItem: index == 0,
                            showBlurHint: index == 0 && showFavoritesBlurHint,
                            onHintDismiss: {
                                showFavoritesBlurHint = false
                                hasShownFavoritesBlurHint = true
                            }
                                    ) {
                                        currentSentence = sentence
                                        currentTopic = getTopicForSentence(sentence)
                                        lastUsedTopic = currentTopic
                                    }
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? geometry.size.width * 0.7 : .infinity)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            favoriteManager.removeFavorite(sentence)
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
    
    @ViewBuilder
    private var homeView: some View {
        VStack(spacing: 0) {
            // Fixed header section
            VStack(spacing: 0) {
                    // Title
                    HStack(spacing: 0) {
                        Text("Talk")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        Text("Svenska")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                    }
                        .padding(.top, 20)
                        .padding(.bottom, 2)
                    
                    // Talking image
                    Image("Talking")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 250 : 160, height: UIDevice.current.userInterfaceIdiom == .pad ? 250 : 160)
                    .padding(.bottom, 12)
                    
                // Subtitle text
                Text("Learn Swedish through real-life conversations")
                    .font(UIDevice.current.userInterfaceIdiom == .pad ? .body : .caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, -20)
                    .padding(.bottom, 8)
                
                // Select Topic text
                        Text("Select Topic")
                            .font(.title2)
                            .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, 20)
                    .padding(.top, 10)
                            .padding(.bottom, 10)
            }
                        
            // Scrollable topics section
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.fixed(UIDevice.current.userInterfaceIdiom == .pad ? 350 : 180)),
                                GridItem(.fixed(UIDevice.current.userInterfaceIdiom == .pad ? 350 : 180))
                            ], spacing: UIDevice.current.userInterfaceIdiom == .pad ? 10 : 10) {
                                ForEach(topics, id: \.self) { topic in
                        TopicCard(
                            topic: topic,
                            isPopular: topic == "Restaurant" || topic == "Shopping"
                        ) { selectedTopic in
                                        handleTopicSelection(selectedTopic)
                                    }
                                }
                            }
                            .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 40 : 20)
                .padding(.bottom, 20)
                    }
                    
            // Fixed footer section
            VStack(spacing: 0) {
                    Button(action: {
                        selectRandomSentenceFromAllTopics()
                    }) {
                        HStack {
                        Text("Random Topic")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 300 : .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                        .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 30 : 20)
            }
                    }
        .background(Color(.systemGroupedBackground))
                }
    
    @ViewBuilder
    private func footerMenu(geometry: GeometryProxy) -> some View {
        // Footer menu with 5 buttons - simple layout with top curved background
        ZStack(alignment: .bottom) {
            // System background extending to bottom including safe area
            VStack(spacing: 0) {
                // Main menu background with curved top edges and shadow
                UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 20)
                    .fill(Color(.systemBackground))
                    .frame(width: geometry.size.width, height: menuHeight)
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: -3)
                
                // Extension to fill bottom safe area
                Rectangle()
                    .fill(Color(.systemBackground))
                    .frame(width: geometry.size.width)
                    .frame(height: geometry.safeAreaInsets.bottom)
            }
            
            // Buttons
            HStack(spacing: menuButtonSpacing) {
                TabBarButton(
                    icon: tabIcon(for: 0),
                    label: tabTitle(for: 0),
                    isCustomIcon: false,
                    isSelected: selectedTab == 0,
                    action: { selectedTab = 0 }
                )
                
                TabBarButton(
                    icon: tabIcon(for: 1),
                    label: tabTitle(for: 1),
                    isCustomIcon: false,
                    isSelected: selectedTab == 1,
                    action: { selectedTab = 1 }
                )
                
                TabBarButton(
                    icon: tabIcon(for: 2),
                    label: tabTitle(for: 2),
                    isCustomIcon: false,
                    isSelected: selectedTab == 2,
                    action: { selectedTab = 2 }
                )
                
                TabBarButton(
                    icon: tabIcon(for: 3),
                    label: tabTitle(for: 3),
                    isCustomIcon: false,
                    isSelected: selectedTab == 3,
                    action: { selectedTab = 3 }
                )
                
                TabBarButton(
                    icon: tabIcon(for: 4),
                    label: tabTitle(for: 4),
                    isCustomIcon: false,
                    isSelected: selectedTab == 4,
                    action: { selectedTab = 4 }
                )
            }
            .frame(width: geometry.size.width, height: menuHeight)
        }
        .zIndex(1) // Ensure menu is above content
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "doc.text.fill"
        case 1: return "star.fill"
        case 2: return "house.fill"
        case 3: return "hand.point.up"
        case 4: return "gearshape.fill"
        default: return "house.fill"
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Test"
        case 1: return "Favorites"
        case 2: return "Home"
        case 3: return "Manual"
        case 4: return "Settings"
        default: return "Home"
        }
    }
    
    private func selectRandomSentenceFromAllTopics() {
        // Test if arrays have content
        print("School sentences count: \(SchoolData.sentences.count)")
        print("Transportation sentences count: \(TransportationData.sentences.count)")
        
        // Create an array of all data sources with their topics
        let allDataSources: [(topic: String, getSentence: () -> Sentence)] = [
            ("School", SchoolData.getRandomSentence),
            ("Transportation", TransportationData.getRandomSentence),
            ("Restaurant", RestaurantData.getRandomSentence),
            ("Travel", TravelData.getRandomSentence),
            ("Shopping", ShoppingData.getRandomSentence),
            ("Weather", WeatherData.getRandomSentence),
            ("Family", FamilyData.getRandomSentence),
            ("Work", WorkData.getRandomSentence),
            ("Hobbies", HobbiesData.getRandomSentence),
            ("Health", HealthData.getRandomSentence),
            ("Directions", DirectionsData.getRandomSentence),
            ("Numbers", NumbersData.getRandomSentence)
        ]
        
        // Select a random data source and get a random sentence
        guard let randomDataSource = allDataSources.randomElement() else {
            print("Failed to get random data source")
            return
        }
        
        currentSentence = randomDataSource.getSentence()
        currentTopic = randomDataSource.topic
        lastUsedTopic = currentTopic
        print("Random sentence selected: \(currentSentence?.swedish ?? "nil") from topic: \(currentTopic)")
        
        // Ensure we have a valid sentence
        guard currentSentence != nil else {
            print("Failed to get random sentence")
            return
        }
    }
    
    private func handleTopicSelection(_ topic: String) {
        print("Topic selected: \(topic)")
        currentTopic = topic
        lastUsedTopic = topic
        
        if topic.lowercased() == "school" {
            currentSentence = SchoolData.getRandomSentence()
            print("School sentence selected: \(currentSentence?.swedish ?? "nil")")
            
            guard currentSentence != nil else {
                print("Failed to get school sentence")
                return
            }
        } else if topic.lowercased() == "transportation" {
            currentSentence = TransportationData.getRandomSentence()
        } else if topic.lowercased() == "restaurant" {
            currentSentence = RestaurantData.getRandomSentence()
        } else if topic.lowercased() == "travel" {
            currentSentence = TravelData.getRandomSentence()
        } else if topic.lowercased() == "shopping" {
            currentSentence = ShoppingData.getRandomSentence()
        } else if topic.lowercased() == "weather" {
            currentSentence = WeatherData.getRandomSentence()
        } else if topic.lowercased() == "family" {
            currentSentence = FamilyData.getRandomSentence()
        } else if topic.lowercased() == "work" {
            currentSentence = WorkData.getRandomSentence()
        } else if topic.lowercased() == "hobbies" {
            currentSentence = HobbiesData.getRandomSentence()
        } else if topic.lowercased() == "health" {
            currentSentence = HealthData.getRandomSentence()
        } else if topic.lowercased() == "directions" {
            currentSentence = DirectionsData.getRandomSentence()
        } else if topic.lowercased() == "numbers" {
            currentSentence = NumbersData.getRandomSentence()
        } else {
            // TODO: Handle other topics
            print("Selected topic: \(topic)")
        }
    }
    
    private func getTopicForSentence(_ sentence: Sentence) -> String {
        // Check which data source contains this sentence by comparing Swedish text
        if SchoolData.sentences.contains(where: { $0.swedish == sentence.swedish }) {
            return "School"
        } else if TransportationData.sentences.contains(where: { $0.swedish == sentence.swedish }) {
            return "Transportation"
        } else if RestaurantData.sentences.contains(where: { $0.swedish == sentence.swedish }) {
            return "Restaurant"
        } else if TravelData.sentences.contains(where: { $0.swedish == sentence.swedish }) {
            return "Travel"
        } else if ShoppingData.sentences.contains(where: { $0.swedish == sentence.swedish }) {
            return "Shopping"
        } else if WeatherData.sentences.contains(where: { $0.swedish == sentence.swedish }) {
            return "Weather"
        } else if FamilyData.sentences.contains(where: { $0.swedish == sentence.swedish }) {
            return "Family"
        } else if WorkData.sentences.contains(where: { $0.swedish == sentence.swedish }) {
            return "Work"
        } else if HobbiesData.sentences.contains(where: { $0.swedish == sentence.swedish }) {
            return "Hobbies"
        } else if HealthData.sentences.contains(where: { $0.swedish == sentence.swedish }) {
            return "Health"
        } else if DirectionsData.sentences.contains(where: { $0.swedish == sentence.swedish }) {
            return "Directions"
        } else if NumbersData.sentences.contains(where: { $0.swedish == sentence.swedish }) {
            return "Numbers"
        } else {
            return "Random"
        }
    }
    
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
    

    
    private func showRandomSentenceModal() {
        print("showRandomSentenceModal called")
        // Add a small delay to ensure the app is fully loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("Executing showRandomSentenceModal after delay")
            // Generate a random sentence
            let randomTopic = self.topics.randomElement() ?? "Random"
            print("Selected random topic: \(randomTopic)")
            
            self.currentSentence = self.getRandomSentenceForTopic(randomTopic)
            self.currentTopic = randomTopic
            self.lastUsedTopic = currentTopic
            print("Random sentence set: \(self.currentSentence?.swedish ?? "nil")")
        }
    }
}

struct TopicCard: View {
    @Environment(\.colorScheme) var colorScheme
    let topic: String
    let isPopular: Bool
    let onTopicSelected: (String) -> Void
    
    var body: some View {
        Button(action: {
            onTopicSelected(topic)
        }) {
            ZStack(alignment: .topTrailing) {
            VStack(spacing: UIDevice.current.userInterfaceIdiom == .pad ? 8 : 4) {
                Image(systemName: iconForTopic(topic))
                    .font(UIDevice.current.userInterfaceIdiom == .pad ? .title2 : .title3)
                    .foregroundColor(.blue)
                
                Text(topic)
                    .font(UIDevice.current.userInterfaceIdiom == .pad ? .body : .caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 350 : .infinity)
            .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 80 : 50)
            .padding(.vertical, 8)
            .background(
                colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
            )
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                // Popular label
                if isPopular {
                    Text("Popular")
                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 10 : 8, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 6 : 4)
                        .padding(.vertical, UIDevice.current.userInterfaceIdiom == .pad ? 2 : 1)
                        .background(Color.green)
                        .cornerRadius(4)
                        .padding(.top, UIDevice.current.userInterfaceIdiom == .pad ? 8 : 10)
                        .padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 8 : 10)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
}

// Shared function for topic icons
func iconForTopic(_ topic: String) -> String {
    switch topic.lowercased() {
    case "transportation": return "car.fill"
    case "restaurant": return "fork.knife"
    case "school": return "graduationcap.fill"
    case "travel": return "airplane"
    case "shopping": return "bag.fill"
    case "weather": return "cloud.sun.fill"
    case "family": return "person.3.fill"
    case "work": return "briefcase.fill"
    case "hobbies": return "gamecontroller.fill"
    case "health": return "heart.fill"
    case "directions": return "location.fill"
    case "numbers": return "number.circle.fill"
    default: return "book.fill"
    }
}

struct FavoriteSentenceCard: View {
    @Environment(\.colorScheme) var colorScheme
    let sentence: Sentence
    let topic: String
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
            
                // Favorites icon on the right (similar to manual "M" icon but with "F")
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Text("F")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
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
                .padding(.trailing, 70) // Padding to avoid F icon
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

struct TabBarButton: View {
    let icon: String
    let label: String
    let isCustomIcon: Bool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Icon
                if isCustomIcon {
                    Image(icon)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(isSelected ? .primary : .secondary)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .primary : .secondary)
                }
                
                // Text below icon
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, -30)
            .padding(.bottom, 6)
        }
        .buttonStyle(PlainButtonStyle())
        .allowsHitTesting(true)
    }
}

#Preview {
    ContentView(showRandomSentence: .constant(false))
}
