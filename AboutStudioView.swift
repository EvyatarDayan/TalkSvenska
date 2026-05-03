import SwiftUI

struct AboutStudioView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // About TalkSvenska Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About TalkSvenska")
                            .font(.title2)
                            .fontWeight(.bold)
                    
                        Text("TalkSvenska is a comprehensive Swedish language learning app designed to help you learn Swedish with ease. Practice with sentences, track your progress, and manage your learning journey. Get accurate translations and never miss a learning opportunity again.")
                        .font(.body)
                        .multilineTextAlignment(.leading)
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // About ABASHELARI Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About ABASHELARI")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("At ABASHELARI, we believe in creating software that makes everyday life simpler, smarter, and more enjoyable. Our mission is to develop innovative digital solutions that blend creativity with technology, offering users tools that are intuitive, reliable, and engaging.")
                        .font(.body)
                        .multilineTextAlignment(.leading)
                    
                        Text("Whether it's educational apps, lifestyle tools, or entertainment experiences, ABASHELARI is dedicated to delivering high-quality products that inspire learning, spark curiosity, and bring value to people around the world.")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                        
                        Text("Driven by passion and guided by innovation, ABASHELARI is committed to continuous improvement and to building software that connects people with what matters most.")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding()
            }
            .navigationTitle("About")
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

#Preview {
    AboutStudioView()
}
