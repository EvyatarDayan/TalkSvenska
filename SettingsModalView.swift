import SwiftUI

struct SettingsModalView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            List {
                // Dark Mode
                HStack {
                    Image(systemName: isDarkMode ? "moon.fill" : "moon")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Dark Mode")
                        .font(.body)
                    
                    Spacer()
                    
                    Toggle("", isOn: $isDarkMode)
                        .labelsHidden()
                }
                .frame(height: 44)
                
                // About
                Button(action: {
                    showingAbout = true
                }) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("About TalkSvenska")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 44)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon Placeholder
                    Image(systemName: "book.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .padding(.top, 40)
                    
                    // App Name and Version
                    VStack(spacing: 8) {
                        Text("TalkSvenska")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Description
                    VStack(spacing: 16) {
                        Text("Learn Swedish with interactive sentences")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text("TalkSvenska helps you learn Swedish through practical sentences organized by topics. Practice pronunciation, understand context, and build your vocabulary with real-world examples.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                    }
                    
                    // Features
                    VStack(spacing: 12) {
                        Text("Features")
                            .font(.headline)
                            .padding(.top, 20)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "speaker.wave.2", text: "Text-to-Speech pronunciation")
                            FeatureRow(icon: "list.bullet", text: "12 different topics")
                            FeatureRow(icon: "shuffle", text: "Random sentence generator")
                            FeatureRow(icon: "eye", text: "Interactive translation reveal")
                            FeatureRow(icon: "moon", text: "Dark mode support")
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
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

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

#Preview {
    SettingsModalView()
}
