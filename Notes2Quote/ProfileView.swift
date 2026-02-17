import SwiftUI

private struct NoAutoCapModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 15.0, *) {
            content.textInputAutocapitalization(.never)
        } else {
            content.autocapitalization(.none)
        }
        #elseif os(watchOS)
        if #available(watchOS 8.0, *) {
            content.textInputAutocapitalization(.never)
        } else {
            content
        }
        #elseif os(visionOS)
        content.textInputAutocapitalization(.never)
        #else
        content
        #endif
    }
}

private extension View {
    func noAutoCapitalization() -> some View { self.modifier(NoAutoCapModifier()) }
}

struct ProfileView: View {
    @AppStorage("businessName") private var businessName: String = ""
    @AppStorage("businessPhone") private var businessPhone: String = ""
    @AppStorage("businessEmail") private var businessEmail: String = ""
    @AppStorage("businessAddress") private var businessAddress: String = ""
    @AppStorage("businessWebsite") private var businessWebsite: String = ""
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "GBP"

    var body: some View {
        NavigationStack {
            HStack {
                Spacer()
                Form {
                    Section("Business Details") {
                        TextField("Business Name", text: $businessName)
                        TextField("Phone", text: $businessPhone)
                        TextField("Email", text: $businessEmail)
                            .noAutoCapitalization()
#if canImport(UIKit)
                            .keyboardType(.emailAddress)
#endif
                        TextField("Website", text: $businessWebsite)
                            .noAutoCapitalization()
#if canImport(UIKit)
                            .keyboardType(.URL)
#endif
                        
                        Picker("Default Currency", selection: $defaultCurrency) {
                            ForEach(AppCurrency.allCases) { currency in
                                Text("\(currency.symbol) \(currency.rawValue)").tag(currency.rawValue)
                            }
                        }
                    }

                    Section("Address") {
                        TextField("Street Address", text: $businessAddress, axis: .vertical)
                            .lineLimit(3...)
                    }

                    Section {
                        if businessName.isEmpty {
                            Text("Please fill in your business details to customize your quotes.")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                }
                .frame(maxWidth: 800)
#if os(macOS)
                .formStyle(.grouped)
#endif
                Spacer()
            }
            .navigationTitle("My Business")
        }
    }
}

#Preview {
    ProfileView()
}
