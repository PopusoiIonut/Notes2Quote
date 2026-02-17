import Foundation
import PDFKit
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
class PDFService {
    static let shared = PDFService()
    
    @MainActor
    func generatePDF(from quote: SavedQuote, business: BusinessInfo) -> Data? {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)) // Standard US Letter
        
        return pdfRenderer.pdfData { context in
            context.beginPage()
            
            let margin: CGFloat = 50
            var currentY: CGFloat = margin
            
            // 1. Header (Business Info)
            let businessNameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.systemBlue
            ]
            business.name.draw(at: CGPoint(x: margin, y: currentY), withAttributes: businessNameAttributes)
            currentY += 30
            
            let contactAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let contactInfo = "\(business.address) | \(business.phone) | \(business.email)"
            contactInfo.draw(at: CGPoint(x: margin, y: currentY), withAttributes: contactAttributes)
            currentY += 40
            
            // 2. Title & Date
            let title = quote.isInvoice ? "INVOICE" : "QUOTE"
            title.draw(at: CGPoint(x: margin, y: currentY), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 18)])
            
            let dateStr = "Date: \(quote.date.formatted(date: .abbreviated, time: .omitted))"
            let dateWidth = dateStr.size(withAttributes: contactAttributes).width
            dateStr.draw(at: CGPoint(x: 612 - margin - dateWidth, y: currentY), withAttributes: contactAttributes)
            currentY += 40
            
            // 3. Customer Info
            let subHeaderAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 12)]
            "TO:".draw(at: CGPoint(x: margin, y: currentY), withAttributes: subHeaderAttr)
            currentY += 15
            
            let customerInfo = "\(quote.customer.name)\n\(quote.customer.address)\n\(quote.customer.phone)"
            customerInfo.draw(in: CGRect(x: margin, y: currentY, width: 250, height: 100), withAttributes: contactAttributes)
            currentY += 70
            
            // 4. Table Header
            let tableHeaderY = currentY
            "Description".draw(at: CGPoint(x: margin, y: tableHeaderY), withAttributes: subHeaderAttr)
            "Hrs".draw(at: CGPoint(x: 400, y: tableHeaderY), withAttributes: subHeaderAttr)
            "Rate".draw(at: CGPoint(x: 460, y: tableHeaderY), withAttributes: subHeaderAttr)
            "Total".draw(at: CGPoint(x: 520, y: tableHeaderY), withAttributes: subHeaderAttr)
            
            currentY += 20
            
            // Draw a line
            let path = UIBezierPath()
            path.move(to: CGPoint(x: margin, y: currentY))
            path.addLine(to: CGPoint(x: 612 - margin, y: currentY))
            path.lineWidth = 1
            UIColor.separator.setStroke()
            path.stroke()
            
            currentY += 10
            
            // 5. Items
            let currency = AppCurrency(rawValue: quote.currencyCode)?.symbol ?? "£"
            
            for item in quote.quoteItems {
                item.description.draw(at: CGPoint(x: margin, y: currentY), withAttributes: contactAttributes)
                String(format: "%.1f", item.hours).draw(at: CGPoint(x: 400, y: currentY), withAttributes: contactAttributes)
                "\(currency)\(String(format: "%.2f", item.pricePerHour))".draw(at: CGPoint(x: 460, y: currentY), withAttributes: contactAttributes)
                "\(currency)\(String(format: "%.2f", item.total))".draw(at: CGPoint(x: 520, y: currentY), withAttributes: contactAttributes)
                currentY += 20
            }
            
            for extra in quote.extraItems {
                extra.name.draw(at: CGPoint(x: margin, y: currentY), withAttributes: contactAttributes)
                "-".draw(at: CGPoint(x: 400, y: currentY), withAttributes: contactAttributes)
                "-".draw(at: CGPoint(x: 460, y: currentY), withAttributes: contactAttributes)
                "\(currency)\(String(format: "%.2f", extra.price))".draw(at: CGPoint(x: 520, y: currentY), withAttributes: contactAttributes)
                currentY += 20
            }
            
            currentY += 30
            
            // 6. Totals
            let totalX: CGFloat = 450
            "Subtotal:".draw(at: CGPoint(x: totalX, y: currentY), withAttributes: contactAttributes)
            "\(currency)\(String(format: "%.2f", quote.subtotal))".draw(at: CGPoint(x: 520, y: currentY), withAttributes: contactAttributes)
            currentY += 15
            
            "Tax (\(Int(quote.taxRate))%):".draw(at: CGPoint(x: totalX, y: currentY), withAttributes: contactAttributes)
            "\(currency)\(String(format: "%.2f", quote.taxAmount))".draw(at: CGPoint(x: 520, y: currentY), withAttributes: contactAttributes)
            currentY += 15
            
            let bigTotalAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 14)]
            "TOTAL:".draw(at: CGPoint(x: totalX, y: currentY), withAttributes: bigTotalAttr)
            "\(currency)\(String(format: "%.2f", quote.totalCost))".draw(at: CGPoint(x: 520, y: currentY), withAttributes: bigTotalAttr)
            
            // 7. Footer
            if !quote.notes.isEmpty {
                currentY += 50
                "Notes:".draw(at: CGPoint(x: margin, y: currentY), withAttributes: subHeaderAttr)
                currentY += 15
                quote.notes.draw(in: CGRect(x: margin, y: currentY, width: 512, height: 100), withAttributes: contactAttributes)
            }
        }
    }
}
#endif
#if !canImport(UIKit)
import CoreGraphics
import CoreText

class PDFService {
    static let shared = PDFService()
    @MainActor
    func generatePDF(from quote: SavedQuote, business: BusinessInfo) -> Data? {
        // Minimal CoreGraphics-based PDF fallback for macOS to ensure compilation
        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return nil }
        ctx.beginPDFPage(nil)
        // Draw simple title text using CoreGraphics
        let title = (quote.isInvoice ? "INVOICE" : "QUOTE") as CFString
        let attrs = [kCTFontAttributeName: CTFontCreateWithName("Helvetica-Bold" as CFString, 18, nil)] as CFDictionary
        let attrStr = CFAttributedStringCreate(nil, title, attrs)!
        let line = CTLineCreateWithAttributedString(attrStr)
        ctx.textPosition = CGPoint(x: 50, y: mediaBox.height - 80)
        CTLineDraw(line, ctx)
        // Draw date
        let dateStr = ("Date: \(quote.date.formatted(date: .abbreviated, time: .omitted))") as CFString
        let dateAttrStr = CFAttributedStringCreate(nil, dateStr, [kCTFontAttributeName: CTFontCreateWithName("Helvetica" as CFString, 10, nil)] as CFDictionary)!
        let dateLine = CTLineCreateWithAttributedString(dateAttrStr)
        ctx.textPosition = CGPoint(x: 50, y: mediaBox.height - 100)
        CTLineDraw(dateLine, ctx)
        ctx.endPDFPage()
        ctx.closePDF()
        return data as Data
    }
}
#endif

