import Foundation
import UniformTypeIdentifiers
import SwiftUI

struct ExportDocument: Transferable {
    let data: Data
    let filename: String
    let contentType: UTType

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: \.contentType) { document in
            document.data
        }
        .suggestedFileName(\.filename)
    }
}
