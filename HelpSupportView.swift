import SwiftUI

struct HelpSupportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var subject = ""
    @State private var description = ""
    @State private var showForm = false
    @State private var showError = false
    @State private var showCallAlert = false
    @State private var alertType: AlertType = .none
    
    enum AlertType {
        case none
        case messageSent
        case callSupport
    }
    
    let supportPhone = "+46 123 456 789"
    
    var allFieldsFilled: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !subject.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Group {
                if showForm {
                    Form {
                        Section(header: Text("Your full name")) {
                            TextField("Full name", text: $fullName)
                        }
                        
                        Section(header: Text("Your Email")) {
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        Section(header: Text("Subject")) {
                            TextField("", text: $subject)
                                .onChange(of: subject) { oldValue, newValue in
                                    if newValue.count > 100 {
                                        subject = String(newValue.prefix(100))
                                    }
                                }
                            HStack {
                                Spacer()
                                Text("\(subject.count)/100")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Section(header: Text("Description")) {
                            TextEditor(text: $description)
                                .frame(height: 120)
                                .onChange(of: description) { oldValue, newValue in
                                    if newValue.count > 400 {
                                        description = String(newValue.prefix(400))
                                    }
                                }
                            HStack {
                                Spacer()
                                Text("\(description.count)/400")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if showError && !allFieldsFilled {
                            Section {
                                Text("All fields are required.")
                                    .foregroundColor(.red)
                                    .font(.subheadline)
                            }
                        }
                        
                        Section {
                            Button(action: {
                                if allFieldsFilled {
                                    alertType = .messageSent
                                    showError = false
                                } else {
                                    showError = true
                                }
                            }) {
                                Text("Send")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(allFieldsFilled ? Color.green : Color.gray)
                                    .cornerRadius(12)
                            }
                            .disabled(!allFieldsFilled)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .navigationTitle("Contact us")
                } else {
                    VStack {
                        Spacer(minLength: 0)
                        VStack(alignment: .center, spacing: 32) {
                            VStack(alignment: .center, spacing: 16) {
                                Text("We'd love to hear from you!")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                Text("Whether you have questions,")
                                    .font(.body)
                                
                                Text("feedback, or just want to say hi,")
                                    .font(.body)
                                
                                Text("feel free to reach out.")
                                    .font(.body)
                                
                                Divider()
                                    .padding(.vertical, 8)
                                    .padding(.top, 32)
                                    .padding(.bottom, 32)
                                
                                Text("Email: abashelariprod@gmail.com")
                                    .font(.subheadline)
                                
                                Text("Website: https://abashelari.com")
                                    .font(.subheadline)
                                
                                Divider()
                                    .padding(.vertical, 8)
                                    .padding(.top, 32)
                            }
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 32)
                            
                            Text("OR")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                            
                            Button(action: {
                                showForm = true
                            }) {
                                Text("Contact form")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.green)
                                    .cornerRadius(12)
                                    .padding(.horizontal, 32)
                            }
                            
                            Text("We aim to respond within 24 hours.")
                                .font(.body)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.vertical, 32)
                    .navigationTitle("Help and support")
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if showForm {
                        Button("Cancel") {
                            showForm = false
                        }
                    } else {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            }
            .alert(isPresented: Binding(
                get: { alertType != .none },
                set: { if !$0 { alertType = .none } }
            )) {
                switch alertType {
                case .messageSent:
                    return Alert(
                        title: Text("Message Sent"),
                        message: Text("Thanks for reaching out!"),
                        dismissButton: .default(Text("OK")) {
                            dismiss()
                        }
                    )
                case .callSupport:
                    return Alert(
                        title: Text("Call Support"),
                        message: Text("Do you want to call \(supportPhone)?"),
                        primaryButton: .default(Text("Yes")) {
                            if let url = URL(string: "tel://" + supportPhone.filter { $0.isNumber }) {
                                UIApplication.shared.open(url)
                            }
                        },
                        secondaryButton: .cancel(Text("No"))
                    )
                case .none:
                    return Alert(title: Text(""), message: Text(""), dismissButton: .default(Text("")))
                }
            }
        }
    }
}

#Preview {
    HelpSupportView()
}
