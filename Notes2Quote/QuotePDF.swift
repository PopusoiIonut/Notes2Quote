import Foundation
import UniformTypeIdentifiers
import SwiftUI

private enum TransferError: Error {
    case importFailed
}

struct QuotePDF: Transferable, Sendable {
    let data: Data
    let filename: String
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .pdf) { (pdf: QuotePDF) async throws -> SentTransferredFile in
            let url = URL.temporaryDirectory.appendingPathComponent(pdf.filename)
            try pdf.data.write(to: url)
            return SentTransferredFile(url)
        } importing: { _ in
            throw TransferError.importFailed
        }
    }
}

