import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedQuote.date, order: .reverse) private var savedQuotes: [SavedQuote]
    @AppStorage("businessName") private var businessName: String = ""
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                List(TemplateType.allCases) { template in
                    NavigationLink {
                        QuoteEditorView(template: template) { savedQuote in
                            modelContext.insert(savedQuote)
                            try? modelContext.save()
                        }
                    } label: {
                        Label(template.rawValue, systemImage: icon(for: template))
                    }
                }
                .navigationTitle("New Quote")
                .listStyle(.plain)
            }
            .tabItem {
                Label("New Quote", systemImage: "plus.circle.fill")
            }
            .tag(0)
            
            NavigationStack {
                List {
                    ForEach(savedQuotes) { quote in
                        NavigationLink {
                            QuoteEditorView(existing: quote) { updatedQuote in
                                // SwiftData objects update automatically if properties are changed,
                                // but if we created a copy, we would insert.
                                // Our QuoteEditorView creates a NEW SavedQuote in onSave.
                                // So we probably want to update properties of 'quote' or replace it.
                                // For simplicity: Remove the old one and insert the new one, or manual property map.
                                // Better check QuoteEditorView implementation.
                                // It returns a NEW SavedQuote struct/class. 
                                // Since we switched SavedQuote to @Model (reference type), let's check QuoteEditorView.
                                // If QuoteEditorView creates a new instance, we should perhaps delete the old one or copy values.
                                // For now, let's assume replacement strategy or simple property copy if easy. 
                                // Actually, easiest for "Save" is to just update the fields.
                                // I'll handle that logic in the closure.
                                quote.customer = updatedQuote.customer
                                quote.quoteItems = updatedQuote.quoteItems
                                quote.extraItems = updatedQuote.extraItems
                                quote.notes = updatedQuote.notes
                                quote.date = updatedQuote.date
                                quote.taxRate = updatedQuote.taxRate
                                quote.isInvoice = updatedQuote.isInvoice
                                try? modelContext.save()
                            }
                        } label: {
                            VStack(alignment: .leading) {
                                Text(quote.title).font(.headline)
                                Text(quote.customer.name).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteQuotes)
                }
                .navigationTitle("Saved")
                .listStyle(.plain)
                .overlay {
                    if savedQuotes.isEmpty {
                        ContentUnavailableView("No Copied Quotes", systemImage: "tray")
                    }
                }
            }
            .tabItem {
                Label("Saved", systemImage: "tray.full.fill")
            }
            .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(2)
        }
        .onAppear {
            if businessName.isEmpty {
                selectedTab = 2
            }
        }
    }
    
    private func icon(for template: TemplateType) -> String {
        switch template {
        case .manVan: return "truck.box"
        case .garageWork: return "wrench.and.screwdriver"
        case .gardenWork: return "leaf"
        case .smallRepairs: return "hammer"
        case .plumbing: return "drop"
        case .roofing: return "house"
        }
    }

    private func deleteQuotes(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(savedQuotes[index])
            }
        }
    }
}

#Preview {
    ContentView()
}

