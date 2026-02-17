import Foundation
import SwiftData

enum TemplateType: String, CaseIterable, Identifiable, Codable {
    case manVan = "Man + Van"
    case garageWork = "Garage Work"
    case gardenWork = "Garden Work"
    case smallRepairs = "Small Repairs"
    case plumbing = "Plumbing"
    case roofing = "Roofing"
    
    var id: String { rawValue }
}

struct QuoteItem: Identifiable, Codable {
    var id = UUID()
    var description: String = ""
    var hours: Double = 0.0
    var pricePerHour: Double = 0.0
    var total: Double { hours * pricePerHour }
    
    enum CodingKeys: String, CodingKey { case id, description, hours, pricePerHour }
}

struct ExtraItem: Identifiable, Codable {
    var id = UUID()
    var name: String = ""
    var price: Double = 0.0
    
    enum CodingKeys: String, CodingKey { case id, name, price }
}

struct Customer: Codable {
    var name: String = ""
    var phone: String = ""
    var email: String = ""
    var address: String = ""

    enum CodingKeys: String, CodingKey { case name, phone, email, address }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(phone, forKey: .phone)
        try container.encode(email, forKey: .email)
        try container.encode(address, forKey: .address)
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.phone = try container.decode(String.self, forKey: .phone)
        self.email = try container.decode(String.self, forKey: .email)
        self.address = try container.decode(String.self, forKey: .address)
    }

    init(name: String = "", phone: String = "", email: String = "", address: String = "") {
        self.name = name
        self.phone = phone
        self.email = email
        self.address = address
    }
}

struct BusinessInfo: Codable {
    var name: String = ""
    var phone: String = ""
    var email: String = ""
    var address: String = ""
    var website: String = ""
}

enum AppCurrency: String, CaseIterable, Identifiable, Codable {
    case gbp = "GBP"
    case usd = "USD"
    case eur = "EUR"
    
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .gbp: return "£"
        case .usd: return "$"
        case .eur: return "€"
        }
    }
}

@Model
final class SavedQuote {
    var id: UUID
    var template: TemplateType
    var quoteItems: [QuoteItem]
    var extraItems: [ExtraItem]
    var notes: String
    var customer: Customer
    var jobAddress: String?
    var taxRate: Double
    var date: Date
    var isInvoice: Bool
    var currencyCode: String
    
    init(template: TemplateType, quoteItems: [QuoteItem], extraItems: [ExtraItem], notes: String, customer: Customer, jobAddress: String?, taxRate: Double, date: Date, isInvoice: Bool = false, currencyCode: String = "GBP") {
        self.id = UUID()
        self.template = template
        self.quoteItems = quoteItems
        self.extraItems = extraItems
        self.notes = notes
        self.customer = customer
        self.jobAddress = jobAddress
        self.taxRate = taxRate
        self.date = date
        self.isInvoice = isInvoice
        self.currencyCode = currencyCode
    }
    
    var quoteNumber: String { "Q-\(id.uuidString.prefix(8))" }
    var subtotal: Double { quoteItems.reduce(0) { $0 + $1.total } + extraItems.reduce(0) { $0 + $1.price } }
    var taxAmount: Double { subtotal * (taxRate / 100) }
    var totalCost: Double { subtotal + taxAmount }
    
    var title: String { "\(template.rawValue) – \(date.formatted(date: .abbreviated, time: .omitted))" }
}
