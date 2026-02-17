import SwiftUI
import PhotosUI
import CoreGraphics
#if canImport(UIKit)
import UIKit
#endif

struct QuoteEditorView: View {
    let template: TemplateType?
    let existing: SavedQuote?
    let onSave: (SavedQuote) -> Void
    let effectiveTemplate: TemplateType

    // Directly access stored business info
    @AppStorage("businessName") private var businessName: String = ""
    @AppStorage("businessPhone") private var businessPhone: String = ""
    @AppStorage("businessEmail") private var businessEmail: String = ""
    @AppStorage("businessAddress") private var businessAddress: String = ""
    @AppStorage("businessWebsite") private var businessWebsite: String = ""
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "GBP"

    private var businessInfo: BusinessInfo {
        BusinessInfo(
            name: businessName,
            phone: businessPhone,
            email: businessEmail,
            address: businessAddress,
            website: businessWebsite
        )
    }

    @State private var quoteItems: [QuoteItem] = [QuoteItem()]
    @State private var extraItems: [ExtraItem] = []
    @State private var notes: String = ""
    @State private var customer: Customer = Customer()
    @State private var jobAddress: String = ""
    @State private var taxRate: Double = 0.0
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var loadedImages: [PlatformImage] = []
    @State private var isInvoiceMode: Bool = false
    @State private var selectedCurrency: String = "GBP"
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dismiss) private var dismiss
    
    init(template: TemplateType? = nil, existing: SavedQuote? = nil, onSave: @escaping (SavedQuote) -> Void) {
        self.template = template
        self.existing = existing
        self.onSave = onSave
        self.effectiveTemplate = existing?.template ?? template!
        if let ex = existing {
            _quoteItems = State(initialValue: ex.quoteItems)
            _extraItems = State(initialValue: ex.extraItems)
            _notes = State(initialValue: ex.notes)
            _customer = State(initialValue: ex.customer)
            _jobAddress = State(initialValue: ex.jobAddress ?? "")
            _taxRate = State(initialValue: ex.taxRate)
            _isInvoiceMode = State(initialValue: ex.isInvoice)
            _selectedCurrency = State(initialValue: ex.currencyCode)
        } else {
            _selectedCurrency = State(initialValue: UserDefaults.standard.string(forKey: "defaultCurrency") ?? "GBP")
        }
    }
    
    private var itemsSubtotal: Double {
        let base: Double = quoteItems.reduce(0.0) { partial, item in
            partial + item.total
        }
        let extras: Double = extraItems.reduce(0.0) { partial, extra in
            partial + extra.price
        }
        return base + extras
    }

    var subtotal: Double { itemsSubtotal }

    var taxAmount: Double {
        let rate = taxRate / 100.0
        return subtotal * rate
    }

    var totalCost: Double {
        subtotal + taxAmount
    }

    private var currencyFormat: FloatingPointFormatStyle<Double>.Currency {
        .currency(code: selectedCurrency)
    }
    
    var body: some View {
        HStack {
            Spacer()
            Form {
                customerSection
                jobAddressSection
                workItemsSection
                extrasSection
                notesSection
                photosSection
                taxesTotalsSection
                exportSection
                saveButton
            }
            .frame(maxWidth: 800)
#if os(macOS)
            .formStyle(.grouped)
#endif
            Spacer()
        }
        .navigationTitle(existing?.title ?? effectiveTemplate.rawValue)
#if canImport(UIKit)
        .scrollContentBackground(.hidden)
#endif
        .onChange(of: selectedPhotos) { _, newValue in
            loadImages(from: newValue)
        }
    }
    
    private var customerSection: some View {
        Section("Customer Details") {
            TextField("Name *", text: $customer.name)
#if canImport(UIKit)
            TextField("Phone", text: $customer.phone)
                .keyboardType(UIKeyboardType.phonePad)
#else
            TextField("Phone", text: $customer.phone)
#endif
#if canImport(UIKit)
            TextField("Email", text: $customer.email)
                .keyboardType(UIKeyboardType.emailAddress)
#else
            TextField("Email", text: $customer.email)
#endif
            TextField("Address", text: $customer.address, axis: .vertical).lineLimit(3...)
        }
    }

    private var jobAddressSection: some View {
        Section("Job Address (if different)") {
            TextField("Job Address", text: $jobAddress, axis: .vertical).lineLimit(3...)
        }
    }

    private var workItemsSection: some View {
        Section("Work Items") {
            ForEach($quoteItems) { $item in
                HStack {
                    TextField("Desc", text: $item.description)
                    TextField("Hrs", value: $item.hours, format: .number).frame(width: 60)
                    TextField("Rate", value: $item.pricePerHour, format: currencyFormat).frame(width: 80)
                    Text(item.total, format: currencyFormat)
                }
            }
            .onDelete { quoteItems.remove(atOffsets: $0) }
            Button("Add Item") { quoteItems.append(QuoteItem()) }
        }
    }

    private var extrasSection: some View {
        Section("Extras") {
            ForEach($extraItems) { $extra in
                HStack {
                    TextField("Name", text: $extra.name)
                    TextField("Price", value: $extra.price, format: currencyFormat)
                }
            }
            .onDelete { extraItems.remove(atOffsets: $0) }
            Button("Add Extra") { extraItems.append(ExtraItem()) }
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextEditor(text: $notes).frame(minHeight: 80)
        }
    }

    private var photosSection: some View {
        Section("Photos") {
            PhotosPicker("Select", selection: $selectedPhotos, matching: .images)
            ScrollView(.horizontal) {
                LazyHGrid(rows: [GridItem(.flexible())]) {
                    ForEach(loadedImages.indices, id: \.self) { idx in
#if canImport(UIKit)
                        Image(uiImage: loadedImages[idx])
                            .resizable()
                            .scaledToFit()
                            .frame(height: sizeClass == .compact ? 80 : 120)
#elseif canImport(AppKit)
                        Image(nsImage: loadedImages[idx])
                            .resizable()
                            .scaledToFit()
                            .frame(height: sizeClass == .compact ? 80 : 120)
#endif
                    }
                }
            }
        }
    }

    private var taxesTotalsSection: some View {
        Section("Taxes & Totals") {
#if canImport(UIKit)
            TextField("Tax Rate %", value: $taxRate, format: .number)
                .keyboardType(UIKeyboardType.decimalPad)
#else
            TextField("Tax Rate %", value: $taxRate, format: .number)
#endif
            HStack {
                Text("Currency").bold()
                Spacer()
                Picker("", selection: $selectedCurrency) {
                    ForEach(AppCurrency.allCases) { currency in
                        Text("\(currency.symbol) \(currency.rawValue)").tag(currency.rawValue)
                    }
                }
                .pickerStyle(.menu)
            }
            HStack { Text("Subtotal").bold(); Spacer(); Text(subtotal, format: currencyFormat) }
            HStack { Text("Tax").bold(); Spacer(); Text(taxAmount, format: currencyFormat) }
            HStack {
                Text("Total").font(.headline).bold()
                Spacer()
                Text(totalCost, format: currencyFormat).font(.headline).bold()
            }
        }
    }

    private var exportSection: some View {
        Section("Export") {
            Toggle("As Invoice", isOn: $isInvoiceMode)
            if let pdf = pdfData {
                let prefix = isInvoiceMode ? "Invoice" : "Quote"
                let filename: String = "\(prefix)-\(existing?.title ?? effectiveTemplate.rawValue)-\(Int((existing?.date ?? Date()).timeIntervalSince1970)).pdf"
                let shareItem: QuotePDF = QuotePDF(data: pdf, filename: filename)
                ShareLink(item: shareItem,
                          subject: Text(filename),
                          preview: SharePreview(filename)) {
                    Label("Share PDF", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    private var saveButton: some View {
        Button("Save") {
            let quote = SavedQuote(
                template: effectiveTemplate,
                quoteItems: quoteItems,
                extraItems: extraItems,
                notes: notes,
                customer: customer,
                jobAddress: jobAddress.isEmpty ? nil : jobAddress,
                taxRate: taxRate,
                date: existing?.date ?? Date(),
                isInvoice: isInvoiceMode,
                currencyCode: selectedCurrency
            )
            onSave(quote)
            dismiss()
        }
        .disabled(customer.name.isEmpty)
    }
    
    @MainActor
    private var pdfData: Data? {
        let preview = DocumentPreview(
            isInvoice: isInvoiceMode,
            quoteItems: quoteItems,
            extraItems: extraItems,
            notes: notes,
            images: loadedImages,
            date: existing?.date ?? Date(),
            customer: customer,
            jobAddress: jobAddress.isEmpty ? nil : jobAddress,
            subtotal: subtotal,
            taxRate: taxRate,
            taxAmount: taxAmount,
            total: totalCost,
            business: businessInfo,
            quoteNumber: existing?.quoteNumber ?? SavedQuote(
                template: effectiveTemplate,
                quoteItems: [],
                extraItems: [],
                notes: "",
                customer: Customer(),
                jobAddress: nil,
                taxRate: 0,
                date: Date(),
                currencyCode: selectedCurrency
            ).quoteNumber,
            currencyCode: selectedCurrency
        )
        let renderer = ImageRenderer(content: preview)
        renderer.scale = 2.0
#if canImport(UIKit)
        guard let cgImage = renderer.uiImage?.cgImage else { return nil }
#elseif canImport(AppKit)
        guard let nsImage = renderer.nsImage, let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
#endif
        var pdfRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &pdfRect, nil) else { return nil }
        context.beginPDFPage(nil)
        context.draw(cgImage, in: pdfRect)
        context.endPDFPage()
        context.closePDF()
        return pdfData as Data
    }
    
    private func loadImages(from items: [PhotosPickerItem]) {
        Task {
            loadedImages = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
#if canImport(UIKit)
                    if let image = UIImage(data: data) { loadedImages.append(image) }
#elseif canImport(AppKit)
                    if let image = NSImage(data: data) { loadedImages.append(image) }
#endif
                }
            }
        }
    }
}

#Preview("Single Template") {
    NavigationStack {
        QuoteEditorView(template: .manVan) { _ in }
            .navigationTitle("Man + Van")
            .frame(width: 500, height: 600)
            .padding()
    }
}
#Preview("Browse Templates") {
    NavigationStack {
        TabView {
            QuoteEditorView(template: .manVan) { _ in }
                .tabItem { Label("Man + Van", systemImage: "truck.box") }
            QuoteEditorView(template: .garageWork) { _ in }
                .tabItem { Label("Garage Work", systemImage: "wrench.and.screwdriver") }
            QuoteEditorView(template: .gardenWork) { _ in }
                .tabItem { Label("Garden Work", systemImage: "leaf") }
            QuoteEditorView(template: .smallRepairs) { _ in }
                .tabItem { Label("Small Repairs", systemImage: "hammer") }
            QuoteEditorView(template: .plumbing) { _ in }
                .tabItem { Label("Plumbing", systemImage: "wrench.adjustable") }
            QuoteEditorView(template: .roofing) { _ in }
                .tabItem { Label("Roofing", systemImage: "house") }
        }
#if os(iOS)
        .tabViewStyle(.page(indexDisplayMode: .automatic))
#endif
        .frame(maxWidth: 700)
        .padding()
    }
}

