import SwiftUI

struct LearningTipsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Tip 1
                    TipSection(
                        number: "1",
                        title: "Learn words inside a sentence (not alone)",
                        description: "Your brain remembers meaning + situation, not lists.",
                        badExample: "äta = to eat",
                        goodExample: "Jag äter frukost.\n\"I eat breakfast.\"",
                        betterExample: "Even better:\nJag äter frukost varje morgon."
                    )
                    
                    // Tip 2
                    TipSection(
                        number: "2",
                        title: "Use active recall, not rereading",
                        description: "Reading feels productive, but testing yourself works better.",
                        simpleMethod: "Simple method:\n• Look at the word\n• Hide it\n• Ask yourself: \"What does this mean?\"\n• Check\n\n30 seconds per word is enough."
                    )
                    
                    // Tip 3
                    TipSection(
                        number: "3",
                        title: "Short, frequent sessions (5–10 min)",
                        description: "The brain forgets fast — and that's normal.",
                        bestSchedule: "Best schedule:\n• 5–10 minutes\n• 1–3 times per day\n• Stop before you feel tired\n\nConsistency > duration."
                    )
                    
                    // Tip 4
                    TipSection(
                        number: "4",
                        title: "Say it out loud (even quietly)",
                        description: "Speaking activates memory differently than reading.",
                        justDo: "Just:\n• Say the word\n• Say the sentence\n• Say the translation\n\nYes, even if your pronunciation isn't perfect."
                    )
                    
                    // Tip 5
                    TipSection(
                        number: "5",
                        title: "Connect the word to you",
                        description: "Personal relevance boosts memory.",
                        insteadOf: "Instead of:\nHan äter middag.",
                        tryThis: "Try:\nJag äter middag klockan sex.\n\nYour brain cares more when you are in the sentence."
                    )
                    
                    // Tip 6
                    TipSection(
                        number: "6",
                        title: "Use spaced repetition (but keep it simple)",
                        description: "You don't need fancy systems.",
                        justReview: "Just review:\n• same day\n• next day\n• 3 days later\n• 1 week later\n\nEven 10 words reviewed beats 50 new ones forgotten."
                    )
                    
                    // What NOT to do
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What NOT to do")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Don't memorize long word lists")
                            Text("• Don't cram for an hour")
                            Text("• Don't rely only on passive reading")
                            Text("• Don't worry about perfection")
                        }
                        .font(.body)
                        .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // Simplest winning routine
                    VStack(alignment: .leading, spacing: 12) {
                        Text("The simplest winning routine (5 minutes)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Pick 5 words")
                            Text("• Read each in a sentence")
                            Text("• Say each out loud once")
                            Text("• Test yourself quickly")
                            Text("• Stop")
                        }
                        .font(.body)
                        .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemGroupedBackground))
            .navigationTitle("Learning Tips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TipSection: View {
    let number: String
    let title: String
    let description: String
    var badExample: String? = nil
    var goodExample: String? = nil
    var betterExample: String? = nil
    var simpleMethod: String? = nil
    var bestSchedule: String? = nil
    var justDo: String? = nil
    var insteadOf: String? = nil
    var tryThis: String? = nil
    var justReview: String? = nil
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                if let badExample = badExample, let goodExample = goodExample {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("❌")
                                .font(.title3)
                            Text("Bad")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                        Text(badExample)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        HStack(alignment: .top, spacing: 8) {
                            Text("✅")
                                .font(.title3)
                            Text("Good")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        Text(goodExample)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        if let betterExample = betterExample {
                            Text(betterExample)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.top, 4)
                }
                
                if let simpleMethod = simpleMethod {
                    Text(simpleMethod)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                }
                
                if let bestSchedule = bestSchedule {
                    Text(bestSchedule)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                }
                
                if let justDo = justDo {
                    Text(justDo)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                }
                
                if let insteadOf = insteadOf, let tryThis = tryThis {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(insteadOf)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Text(tryThis)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 4)
                }
                
                if let justReview = justReview {
                    Text(justReview)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    LearningTipsView()
}
