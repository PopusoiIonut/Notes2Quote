import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct CustomerFormSection: View {
    @Binding var customer: Customer
    var body: some View {
        Section("Customer Details") {
            TextField("Name *", text: $customer.name)
                .accessibilityLabel("Customer Name")
                .accessibilityHint("Enter the full name of the client")
            
            TextField("Phone", text: $customer.phone)
#if canImport(UIKit)
                .keyboardType(UIKeyboardType.phonePad)
#endif
                .accessibilityLabel("Phone Number")
            
            TextField("Email", text: $customer.email)
#if canImport(UIKit)
                .keyboardType(UIKeyboardType.emailAddress)
#endif
                .accessibilityLabel("Email Address")
            
            TextField("Address", text: $customer.address, axis: .vertical)
                .lineLimit(3...)
                .accessibilityLabel("Billing Address")
        }
    }
}

struct WorkItemsSection: View {
    @Binding var items: [QuoteItem]
    let currencyFormat: FloatingPointFormatStyle<Double>.Currency
    
    var body: some View {
        Section("Work Items") {
            ForEach($items) { $item in
                HStack {
                    TextField("Description", text: $item.description)
                    TextField("Hrs", value: $item.hours, format: .number)
                        .frame(width: 50)
                    TextField("Rate", value: $item.pricePerHour, format: currencyFormat)
                        .frame(width: 70)
                    Text(item.total, format: currencyFormat)
                        .font(.caption.bold())
                }
            }
            .onDelete { items.remove(atOffsets: $0) }
            
            Button(action: { items.append(QuoteItem()) }) {
                Label("Add Line Item", systemImage: "plus.circle")
            }
            .accessibilityLabel("Add New Work Item")
        }
    }
}

struct TotalsSection: View {
    let subtotal: Double
    let taxAmount: Double
    let total: Double
    @Binding var taxRate: Double
    @Binding var currencyCode: String
    let currencyFormat: FloatingPointFormatStyle<Double>.Currency
    
    var body: some View {
        Section("Taxes & Totals") {
            HStack {
                Text("Tax Rate")
                Spacer()
                TextField("%", value: $taxRate, format: .number)
#if canImport(UIKit)
                    .keyboardType(UIKeyboardType.decimalPad)
#endif
                    .multilineTextAlignment(TextAlignment.trailing)
                    .frame(width: 60)
            }
            
            Picker("Currency", selection: $currencyCode) {
                ForEach(AppCurrency.allCases) { currency in
                    Text("\(currency.symbol) \(currency.rawValue)").tag(currency.rawValue)
                }
            }
            
            LabeledContent("Subtotal", value: subtotal, format: currencyFormat)
            LabeledContent("Tax", value: taxAmount, format: currencyFormat)
            LabeledContent("Total") {
                Text(total, format: currencyFormat)
                    .font(.headline.bold())
                    .foregroundStyle(.blue)
            }
        }
    }
}
