import SwiftUI

struct DocumentPreview: View {
    let isInvoice: Bool
    let quoteItems: [QuoteItem]
    let extraItems: [ExtraItem]
    let notes: String
    let images: [PlatformImage]
    let date: Date
    let customer: Customer
    let jobAddress: String?
    let subtotal: Double
    let taxRate: Double
    let taxAmount: Double
    let total: Double
    let business: BusinessInfo
    let quoteNumber: String
    let currencyCode: String
    
    var validUntil: Date { Calendar.current.date(byAdding: .day, value: 30, to: date) ?? date }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(Text("LOGO").font(.caption.bold()))
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(business.name.uppercased())
                        .font(.title2.bold())
                    Text(business.address)
                        .font(.caption)
                    Text("\(business.phone) • \(business.email)")
                        .font(.caption)
                    if !business.website.isEmpty { Text(business.website).font(.caption) }
                }
            }
            Divider().frame(height: 2).background(Color.black)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isInvoice ? "INVOICE" : "QUOTE")
                        .font(.largeTitle.bold())
                    Text("No: \(quoteNumber)")
                        .font(.subheadline)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                    Text("Valid until: \(validUntil.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline.italic())
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Bill To:").font(.headline)
                Text(customer.name).bold()
                Text(customer.address)
                if !customer.phone.isEmpty { Text("Ph: \(customer.phone)") }
                if !customer.email.isEmpty { Text("Email: \(customer.email)") }
            }
            if let job = jobAddress, !job.isEmpty {
                Text("Job Location: \(job)").italic()
            }
            Spacer(minLength: 24)
            Text(isInvoice ? "Services / Items" : "Quoted Services")
                .font(.title3.bold())
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("Description").font(.caption.bold()).frame(maxWidth: .infinity, alignment: .leading)
                    Text("Qty/Hrs").font(.caption.bold()).frame(width: 60, alignment: .trailing)
                    Text("Rate").font(.caption.bold()).frame(width: 80, alignment: .trailing)
                    Text("Amount").font(.caption.bold()).frame(width: 80, alignment: .trailing)
                }
                .padding(.bottom, 8)
                Divider()
                
                // Rows
                ForEach(quoteItems) { item in
                    HStack(alignment: .top) {
                        Text(item.description).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                        Text(String(format: "%.1f", item.hours)).font(.caption).frame(width: 60, alignment: .trailing)
                        Text(item.pricePerHour, format: .currency(code: currencyCode)).font(.caption).frame(width: 80, alignment: .trailing)
                        Text(item.total, format: .currency(code: currencyCode)).bold().font(.caption).frame(width: 80, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            }
            
            if !extraItems.isEmpty {
                Spacer(minLength: 16)
                Text("Extras").font(.headline)
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        Text("Item").font(.caption.bold()).frame(maxWidth: .infinity, alignment: .leading)
                        Text("Price").font(.caption.bold()).frame(width: 80, alignment: .trailing)
                    }
                    .padding(.bottom, 8)
                    Divider()
                    
                    // Rows
                    ForEach(extraItems) { extra in
                        HStack(alignment: .top) {
                            Text(extra.name).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                            Text(extra.price, format: .currency(code: currencyCode)).bold().font(.caption).frame(width: 80, alignment: .trailing)
                        }
                        .padding(.vertical, 4)
                        Divider()
                    }
                }
            }
            VStack(spacing: 8) {
                Divider()
                HStack {
                    Spacer()
                    Text("Subtotal:").bold()
                    Text(subtotal, format: .currency(code: currencyCode)).bold()
                        .frame(width: 140, alignment: .trailing)
                }
                HStack {
                    Spacer()
                    Text("Tax (\(String(format: "%.2f", taxRate))%):").bold()
                    Text(taxAmount, format: .currency(code: currencyCode)).bold()
                        .frame(width: 140, alignment: .trailing)
                }
                Divider()
                HStack {
                    Spacer()
                    Text(isInvoice ? "TOTAL DUE:" : "TOTAL QUOTE:")
                        .font(.title3.bold())
                    Text(total, format: .currency(code: currencyCode))
                        .font(.title3.bold())
                        .frame(width: 140, alignment: .trailing)
                }
            }
            if !notes.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Notes / Terms").font(.headline)
                    Text(notes).font(.caption)
                }
            }
            if !images.isEmpty {
                Spacer(minLength: 10)
                Text("Photos").font(.headline)
                HStack(spacing: 8) {
                    ForEach(images.prefix(3).indices, id: \.self) { idx in
#if canImport(UIKit)
                        Image(uiImage: images[idx])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipped()
                            .border(Color.gray, width: 1)
#elseif canImport(AppKit)
                        Image(nsImage: images[idx])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipped()
                            .border(Color.gray, width: 1)
#endif
                    }
                }
            }
            Spacer()
            Text("Thank you for your business! Payment due within 14 days. Questions? Contact us anytime.")
                .font(.footnote.italic())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(32)
        .frame(width: 595, height: 842)
        .background(Color.white)
    }
}
